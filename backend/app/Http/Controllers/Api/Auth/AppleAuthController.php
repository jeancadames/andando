<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\Legal\CustomerLegalOnboardingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Kreait\Laravel\Firebase\Facades\Firebase;
use Throwable;

class AppleAuthController extends Controller
{
    public function __construct(
        private readonly CustomerLegalOnboardingService $onboardingService
    ) {
    }

    public function __invoke(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => ['required', 'string'],
        ], [
            'id_token.required' => 'El token de Apple es obligatorio.',
        ]);

        try {
            $firebaseAuth = Firebase::project('app')->auth();

            $verifiedToken = $firebaseAuth->verifyIdToken(
                $validated['id_token']
            );

            $firebaseUid = $verifiedToken->claims()->get('sub');
            $email = $verifiedToken->claims()->get('email');
            $name = $verifiedToken->claims()->get('name');
            $picture = $verifiedToken->claims()->get('picture');
            $emailVerified = (bool) $verifiedToken
                ->claims()
                ->get('email_verified');
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'message' => 'No pudimos validar tu cuenta de Apple.',
            ], 401);
        }

        $email = $email
            ? strtolower(trim((string) $email))
            : null;

        $firebaseUid = $firebaseUid
            ? trim((string) $firebaseUid)
            : null;

        if (! $email) {
            return response()->json([
                'message' => 'No pudimos obtener el correo de tu cuenta de Apple.',
            ], 422);
        }

        if (! $firebaseUid) {
            return response()->json([
                'message' => 'No pudimos obtener el identificador de tu cuenta de Apple.',
            ], 422);
        }

        $userByFirebaseUid = User::query()
            ->where('firebase_uid', $firebaseUid)
            ->first();

        $userByEmail = User::query()
            ->where('email', $email)
            ->first();

        if (
            $userByFirebaseUid
            && $userByEmail
            && (int) $userByFirebaseUid->id !== (int) $userByEmail->id
        ) {
            return response()->json([
                'message' => 'Esta cuenta de Apple ya está vinculada a otro usuario.',
            ], 409);
        }

        $existingUser = $userByFirebaseUid ?: $userByEmail;

        if ($existingUser && $existingUser->type !== 'customer') {
            return response()->json([
                'message' => 'Esta cuenta ya existe como afiliado. Por ahora Apple Auth está habilitado solo para clientes.',
            ], 403);
        }

        $user = DB::transaction(function () use (
            $existingUser,
            $email,
            $name,
            $picture,
            $firebaseUid,
            $emailVerified
        ): User {
            if (! $existingUser) {
                $user = User::query()->create([
                    'name' => $name ?: Str::before($email, '@'),
                    'email' => $email,
                    'phone' => null,
                    'type' => 'customer',
                    'password' => Hash::make(Str::random(40)),
                    'firebase_uid' => $firebaseUid,
                    'avatar_url' => $picture,
                ]);
            } else {
                $user = $existingUser;

                $user->forceFill([
                    'firebase_uid' => $user->firebase_uid ?: $firebaseUid,
                    'avatar_url' => $user->avatar_url ?: $picture,
                ])->save();
            }

            if ($emailVerified && ! $user->email_verified_at) {
                $user->forceFill([
                    'email_verified_at' => now(),
                ])->save();
            }

            return $user;
        });

        $user->refresh();

        $requiresLegalOnboarding = ! $this->onboardingService
            ->isComplete($user);

        $token = $user
            ->createToken('customer-apple')
            ->plainTextToken;

        return response()->json([
            'message' => $requiresLegalOnboarding
                ? 'Cuenta de Apple validada. Completa tu información legal para continuar.'
                : 'Inicio de sesión con Apple exitoso.',

            'token' => $token,

            'requires_legal_onboarding' => $requiresLegalOnboarding,

            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'birth_date' => $user->birth_date?->format('Y-m-d'),
                'type' => $user->type,
                'avatar_url' => $user->avatar_url,
                'firebase_uid' => $user->firebase_uid,
            ],
        ]);
    }
}