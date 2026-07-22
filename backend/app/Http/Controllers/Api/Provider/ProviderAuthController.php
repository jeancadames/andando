<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Http\Requests\Provider\ProviderLoginRequest;
use App\Http\Requests\Provider\ProviderRegisterRequest;
use App\Models\LegalDocument;
use App\Models\Provider;
use App\Models\ProviderBusinessType;
use App\Models\ProviderDocument;
use App\Models\ProviderVerificationRequest;
use App\Models\User;
use App\Notifications\Admin\NewProviderPendingReviewNotification;
use App\Notifications\Auth\WelcomeProviderNotification;
use App\Services\Legal\LegalAcceptanceService;
use App\Services\Legal\LegalDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Throwable;

/// Controlador de autenticación y registro de proveedores.
class ProviderAuthController extends Controller
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService,
        private readonly LegalAcceptanceService $legalAcceptanceService,
    ) {
    }

    /// Registra un proveedor completo.
    ///
    /// Este endpoint crea:
    /// - usuario
    /// - perfil proveedor
    /// - solicitud de verificación
    /// - documentos
    /// - aceptaciones legales
    /// - token de acceso móvil
    public function register(
        ProviderRegisterRequest $request
    ): JsonResponse {
        $validated = $request->validated();

        /*
         * Validamos los documentos legales antes de crear cualquier
         * usuario, proveedor o archivo.
         */
        $termsDocument = $this->validateLegalDocument(
            documentId: (int) $validated['terms_document_id'],
            checksum: $validated['terms_document_checksum'],
            expectedType: 'terms_provider',
            idField: 'terms_document_id',
            checksumField: 'terms_document_checksum',
        );

        $standardsDocument = $this->validateLegalDocument(
            documentId: (int) $validated['standards_document_id'],
            checksum: $validated['standards_document_checksum'],
            expectedType: 'provider_standards',
            idField: 'standards_document_id',
            checksumField: 'standards_document_checksum',
        );

        $privacyDocument = $this->validateLegalDocument(
            documentId: (int) $validated['privacy_document_id'],
            checksum: $validated['privacy_document_checksum'],
            expectedType: 'privacy',
            idField: 'privacy_document_id',
            checksumField: 'privacy_document_checksum',
        );

        try {
            $result = DB::transaction(function () use (
                $request,
                $validated,
                $termsDocument,
                $standardsDocument,
                $privacyDocument,
            ): array {
                /*
                 * Buscamos el tipo de negocio activo.
                 */
                $businessType = ProviderBusinessType::query()
                    ->where(
                        'slug',
                        $validated['business_type_slug']
                    )
                    ->where('is_active', true)
                    ->firstOrFail();

                /*
                 * Creamos el usuario.
                 */
                $user = User::query()->create([
                    'name' => $validated['full_name'],
                    'email' => strtolower($validated['email']),
                    'phone' => $validated['phone'],
                    'type' => 'provider',
                    'password' => Hash::make(
                        $validated['password']
                    ),
                ]);

                /*
                 * Creamos el perfil del proveedor.
                 */
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

                /*
                 * Conservamos los campos legales antiguos dentro de
                 * provider_verification_requests por compatibilidad.
                 *
                 * Las versiones ya no están hardcodeadas: salen de
                 * los documentos legales realmente publicados.
                 */
                $acceptedAt = now();

                $verificationRequest =
                    ProviderVerificationRequest::query()->create([
                        'provider_id' => $provider->id,
                        'status' => 'pending',
                        'submitted_at' => $acceptedAt,

                        'terms_accepted' => true,
                        'terms_accepted_at' => $acceptedAt,
                        'terms_version' => $termsDocument->version,

                        'privacy_accepted' => true,
                        'privacy_accepted_at' => $acceptedAt,
                        'privacy_version' => $privacyDocument->version,
                    ]);

                /*
                 * Registramos la evidencia auditable de los tres
                 * documentos legales.
                 */
                $acceptanceMetadata = [
                    'flow' => 'provider_registration',
                    'verification_request_id' =>
                        $verificationRequest->id,
                ];

                $termsAcceptance =
                    $this->legalAcceptanceService
                        ->acceptForProvider(
                            provider: $provider,
                            documentId: $termsDocument->id,
                            checksum: $termsDocument->checksum,
                            request: $request,
                            context: [
                                'metadata' => array_merge(
                                    $acceptanceMetadata,
                                    [
                                        'document_role' =>
                                            'provider_terms',
                                    ]
                                ),
                            ],
                        );

                $standardsAcceptance =
                    $this->legalAcceptanceService
                        ->acceptForProvider(
                            provider: $provider,
                            documentId: $standardsDocument->id,
                            checksum: $standardsDocument->checksum,
                            request: $request,
                            context: [
                                'metadata' => array_merge(
                                    $acceptanceMetadata,
                                    [
                                        'document_role' =>
                                            'provider_standards',
                                    ]
                                ),
                            ],
                        );

                $privacyAcceptance =
                    $this->legalAcceptanceService
                        ->acceptForProvider(
                            provider: $provider,
                            documentId: $privacyDocument->id,
                            checksum: $privacyDocument->checksum,
                            request: $request,
                            context: [
                                'metadata' => array_merge(
                                    $acceptanceMetadata,
                                    [
                                        'document_role' =>
                                            'privacy_acknowledgement',
                                    ]
                                ),
                            ],
                        );

                /*
                 * Guardamos los documentos de verificación.
                 */
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

                /*
                 * Creamos el token móvil.
                 */
                $token = $user
                    ->createToken('provider-mobile')
                    ->plainTextToken;

                /*
                 * Recargamos las relaciones necesarias.
                 */
                $provider->load([
                    'businessType',
                    'verificationRequests.documents',
                ]);

                return [
                    'user' => $user,
                    'provider' => $provider,
                    'verification_request' =>
                        $verificationRequest->load('documents'),
                    'token' => $token,
                    'legal_acceptances' => [
                        $termsAcceptance,
                        $standardsAcceptance,
                        $privacyAcceptance,
                    ],
                ];
            });

            $result['user']->load('provider');

            $result['user']->notify(
                new WelcomeProviderNotification()
            );

            User::query()
                ->where('type', 'admin')
                ->get()
                ->each(function (User $admin) use ($result): void {
                    $admin->notify(
                        new NewProviderPendingReviewNotification(
                            $result['provider']
                        )
                    );
                });

            return response()->json([
                'message' =>
                    'Solicitud de proveedor enviada correctamente.',

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
                    'business_name' =>
                        $result['provider']->business_name,
                    'status' => $result['provider']->status,
                    'rejection_reason' =>
                        $result['provider']->rejection_reason,

                    'business_type' => [
                        'slug' =>
                            $result['provider']->businessType->slug,
                        'name' =>
                            $result['provider']->businessType->name,
                    ],
                ],

                'verification_request' => [
                    'id' =>
                        $result['verification_request']->id,
                    'status' =>
                        $result['verification_request']->status,
                    'submitted_at' =>
                        $result['verification_request']->submitted_at,
                ],

                'legal_acceptances' => collect(
                    $result['legal_acceptances']
                )->map(function ($acceptance): array {
                    return [
                        'id' => $acceptance->id,
                        'legal_document_id' =>
                            $acceptance->legal_document_id,
                        'accepted_at' =>
                            $acceptance->accepted_at,
                        'document_checksum' =>
                            $acceptance->document_checksum,
                    ];
                })->values(),
            ], 201);
        } catch (ValidationException $e) {
            /*
             * Laravel debe devolver los errores de validación
             * originales con HTTP 422.
             */
            throw $e;
        } catch (Throwable $e) {
            report($e);

            return response()->json([
                'message' =>
                    'No se pudo crear la solicitud de proveedor.',
            ], 500);
        }
    }

    /// Login de proveedor.
    ///
    /// Permite iniciar sesión aunque el proveedor esté pending,
    /// para que pueda consultar su estado de verificación.
    public function login(
        ProviderLoginRequest $request
    ): JsonResponse {
        $validated = $request->validated();

        $user = User::query()
            ->where(
                'email',
                strtolower($validated['email'])
            )
            ->where('type', 'provider')
            ->first();

        if (
            ! $user
            || ! Hash::check(
                $validated['password'],
                $user->password
            )
        ) {
            throw ValidationException::withMessages([
                'email' => [
                    'Las credenciales no son correctas.',
                ],
            ]);
        }

        $provider = $user->provider()
            ->with('businessType')
            ->first();

        if (! $provider) {
            throw ValidationException::withMessages([
                'email' => [
                    'Este usuario no tiene perfil de proveedor.',
                ],
            ]);
        }

        $token = $user
            ->createToken('provider-mobile')
            ->plainTextToken;

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
                'rejection_reason' =>
                    $provider->rejection_reason,

                'business_type' => [
                    'slug' => $provider->businessType->slug,
                    'name' => $provider->businessType->name,
                ],
            ],
        ]);
    }

    /// Devuelve el usuario autenticado actual.
    public function me(
        Request $request
    ): JsonResponse {
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

            'provider' => $provider
                ? [
                    'id' => $provider->id,
                    'business_name' =>
                        $provider->business_name,
                    'status' => $provider->status,
                    'rejection_reason' =>
                        $provider->rejection_reason,

                    'business_type' => [
                        'slug' =>
                            $provider->businessType->slug,
                        'name' =>
                            $provider->businessType->name,
                    ],
                ]
                : null,
        ]);
    }

    /// Cierra sesión eliminando el token actual.
    public function logout(
        Request $request
    ): JsonResponse {
        $request->user()
            ?->currentAccessToken()
            ?->delete();

        return response()->json([
            'message' =>
                'Sesión cerrada correctamente.',
        ]);
    }

    /**
     * Valida que un documento:
     * - exista y esté vigente;
     * - tenga integridad válida;
     * - pertenezca a proveedores;
     * - sea del tipo esperado;
     * - coincida con el checksum recibido.
     */
    private function validateLegalDocument(
        int $documentId,
        string $checksum,
        string $expectedType,
        string $idField,
        string $checksumField,
    ): LegalDocument {
        $document = $this->legalDocumentService
            ->findCurrentById($documentId);

        if ($document === null) {
            throw ValidationException::withMessages([
                $idField => [
                    'El documento legal indicado no está vigente o no superó la validación de integridad.',
                ],
            ]);
        }

        if ($document->audience !== 'provider') {
            throw ValidationException::withMessages([
                $idField => [
                    'El documento legal indicado no corresponde a proveedores.',
                ],
            ]);
        }

        if ($document->type !== $expectedType) {
            throw ValidationException::withMessages([
                $idField => [
                    'El documento legal indicado no corresponde al tipo requerido.',
                ],
            ]);
        }

        if (! $this->legalDocumentService->checksumMatches(
            $document,
            $checksum
        )) {
            throw ValidationException::withMessages([
                $checksumField => [
                    'La versión del documento legal no coincide con la versión publicada.',
                ],
            ]);
        }

        /*
         * También comprobamos que el ID enviado corresponda al
         * documento vigente seleccionado por tipo y audiencia.
         */
        $currentDocument = $this->legalDocumentService
            ->current(
                $expectedType,
                'provider'
            );

        if (
            $currentDocument === null
            || (int) $currentDocument->id !== (int) $document->id
        ) {
            throw ValidationException::withMessages([
                $idField => [
                    'El documento legal indicado ya no es la versión vigente.',
                ],
            ]);
        }

        return $document;
    }

    /// Guarda un documento en storage privado y crea su registro.
    private function storeDocument(
        ProviderRegisterRequest $request,
        Provider $provider,
        ProviderVerificationRequest $verificationRequest,
        string $inputName,
        string $type,
    ): ProviderDocument {
        $file = $request->file($inputName);

        $directory = implode('/', [
            'providers',
            $provider->id,
            'verification_requests',
            $verificationRequest->id,
        ]);

        $path = $file->store(
            $directory,
            'private'
        );

        return ProviderDocument::query()->create([
            'provider_id' => $provider->id,
            'provider_verification_request_id' =>
                $verificationRequest->id,
            'type' => $type,
            'status' => 'pending',
            'disk' => 'private',
            'path' => $path,
            'original_name' =>
                $file->getClientOriginalName(),
            'mime_type' =>
                $file->getClientMimeType(),
            'size_bytes' =>
                $file->getSize(),
        ]);
    }
}