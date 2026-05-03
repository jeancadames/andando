<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Http\Requests\Provider\ProviderLoginRequest;
use App\Http\Requests\Provider\ProviderRegisterRequest;
use App\Models\Provider;
use App\Models\ProviderBusinessType;
use App\Models\ProviderDocument;
use App\Models\ProviderVerificationRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

/// Controlador de autenticación y registro de proveedores.
class ProviderAuthController extends Controller
{
    /// Registra un proveedor completo.
    ///
    /// Este endpoint crea:
    /// - usuario
    /// - perfil proveedor
    /// - solicitud de verificación
    /// - documentos
    /// - token de acceso móvil
    public function register(ProviderRegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        try {
            $result = DB::transaction(function () use ($request, $validated) {
                /// Buscamos el tipo de negocio por slug.
                $businessType = ProviderBusinessType::query()
                    ->where('slug', $validated['business_type_slug'])
                    ->where('is_active', true)
                    ->firstOrFail();

                /// Creamos el usuario.
                $user = User::query()->create([
                    'name' => $validated['full_name'],
                    'email' => strtolower($validated['email']),
                    'phone' => $validated['phone'],
                    'type' => 'provider',
                    'password' => Hash::make($validated['password']),
                ]);

                /// Creamos el perfil de proveedor.
                $provider = Provider::query()->create([
                    'user_id' => $user->id,
                    'provider_business_type_id' => $businessType->id,
                    'business_name' => $validated['business_name'],
                    'rnc' => $validated['rnc'],
                    'address' => $validated['address'],
                    'city' => $validated['city'],
                    'province' => $validated['province'],
                    'status' => 'pending',
                ]);

                /// Creamos la solicitud de verificación.
                $verificationRequest = ProviderVerificationRequest::query()->create([
                    'provider_id' => $provider->id,
                    'status' => 'pending',
                    'submitted_at' => now(),
                    'terms_accepted' => true,
                    'terms_accepted_at' => now(),
                    'terms_version' => '1.0',
                    'privacy_accepted' => true,
                    'privacy_accepted_at' => now(),
                    'privacy_version' => '1.0',
                ]);

                /// Guardamos documentos.
                $this->storeDocument(
                    request: $request,
                    provider: $provider,
                    verificationRequest: $verificationRequest,
                    inputName: 'identity_card',
                    type: 'identity_card',
                );

                $this->storeDocument(
                    request: $request,
                    provider: $provider,
                    verificationRequest: $verificationRequest,
                    inputName: 'rnc_certificate',
                    type: 'rnc_certificate',
                );

                if ($request->hasFile('business_license')) {
                    $this->storeDocument(
                        request: $request,
                        provider: $provider,
                        verificationRequest: $verificationRequest,
                        inputName: 'business_license',
                        type: 'business_license',
                    );
                }

                /// Creamos token móvil.
                $token = $user->createToken('provider-mobile')->plainTextToken;

                /// Recargamos relaciones para devolver respuesta completa.
                $provider->load(['businessType', 'verificationRequests.documents']);

                return [
                    'user' => $user,
                    'provider' => $provider,
                    'verification_request' => $verificationRequest->load('documents'),
                    'token' => $token,
                ];
            });

            return response()->json([
                'message' => 'Solicitud de proveedor enviada correctamente.',
                'token' => $result['token'],
                'user' => [
                    'id' => $result['user']->id,
                    'name' => $result['user']->name,
                    'email' => $result['user']->email,
                    'phone' => $result['user']->phone,
                    'type' => $result['user']->type,
                ],
                'provider' => [
                    'id' => $result['provider']->id,
                    'business_name' => $result['provider']->business_name,
                    'status' => $result['provider']->status,
                    'rejection_reason' => $result['provider']->rejection_reason,
                    'business_type' => [
                        'slug' => $result['provider']->businessType->slug,
                        'name' => $result['provider']->businessType->name,
                    ],
                ],
                'verification_request' => [
                    'id' => $result['verification_request']->id,
                    'status' => $result['verification_request']->status,
                    'submitted_at' => $result['verification_request']->submitted_at,
                ],
            ], 201);
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'message' => 'No se pudo crear la solicitud de proveedor.',
            ], 500);
        }
    }

    /// Login de proveedor.
    ///
    /// Permite iniciar sesión aunque el proveedor esté pending,
    /// para que pueda ver su estado de verificación.
    public function login(ProviderLoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::query()
            ->where('email', strtolower($validated['email']))
            ->where('type', 'provider')
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Las credenciales no son correctas.'],
            ]);
        }

        $provider = $user->provider()
            ->with('businessType')
            ->first();

        if (! $provider) {
            throw ValidationException::withMessages([
                'email' => ['Este usuario no tiene perfil de proveedor.'],
            ]);
        }

        $token = $user->createToken('provider-mobile')->plainTextToken;

        return response()->json([
            'message' => 'Inicio de sesión correcto.',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'type' => $user->type,
            ],
            'provider' => [
                'id' => $provider->id,
                'business_name' => $provider->business_name,
                'status' => $provider->status,
                'rejection_reason' => $provider->rejection_reason,
                'business_type' => [
                    'slug' => $provider->businessType->slug,
                    'name' => $provider->businessType->name,
                ],
            ],
        ]);
    }

    /// Devuelve el usuario autenticado actual.
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        $provider = $user->provider()
            ->with('businessType')
            ->first();

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'type' => $user->type,
            ],
            'provider' => $provider ? [
                'id' => $provider->id,
                'business_name' => $provider->business_name,
                'status' => $provider->status,
                'rejection_reason' => $provider->rejection_reason,
                'business_type' => [
                    'slug' => $provider->businessType->slug,
                    'name' => $provider->businessType->name,
                ],
            ] : null,
        ]);
    }

    /// Cierra sesión eliminando el token actual.
    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Sesión cerrada correctamente.',
        ]);
    }

    /// Guarda un documento en storage privado y crea registro en BD.
    private function storeDocument(
        ProviderRegisterRequest $request,
        Provider $provider,
        ProviderVerificationRequest $verificationRequest,
        string $inputName,
        string $type,
    ): ProviderDocument {
        $file = $request->file($inputName);

        $directory = "providers/{$provider->id}/verification_requests/{$verificationRequest->id}";

        $path = $file->store($directory, 'private');

        return ProviderDocument::query()->create([
            'provider_id' => $provider->id,
            'provider_verification_request_id' => $verificationRequest->id,
            'type' => $type,
            'status' => 'pending',
            'disk' => 'private',
            'path' => $path,
            'original_name' => $file->getClientOriginalName(),
            'mime_type' => $file->getClientMimeType(),
            'size_bytes' => $file->getSize(),
        ]);
    }
}