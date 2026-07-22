<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\CompleteSocialLegalOnboardingRequest;
use App\Models\User;
use App\Services\Legal\CustomerLegalOnboardingService;
use App\Services\Legal\LegalAcceptanceService;
use App\Services\Legal\LegalDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SocialLegalOnboardingController extends Controller
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService,
        private readonly LegalAcceptanceService $legalAcceptanceService,
        private readonly CustomerLegalOnboardingService $onboardingService
    ) {
    }

    public function __invoke(
        CompleteSocialLegalOnboardingRequest $request
    ): JsonResponse {
        /** @var User|null $user */
        $user = $request->user();

        if ($user === null) {
            return response()->json([
                'message' => 'No se pudo identificar al usuario autenticado.',
            ], 401);
        }

        if ($user->type !== 'customer') {
            return response()->json([
                'message' => 'Este proceso está disponible únicamente para clientes.',
            ], 403);
        }

        $validated = $request->validated();

        $terms = $this->legalDocumentService->current(
            'terms_user',
            'customer'
        );

        $privacy = $this->legalDocumentService->current(
            'privacy',
            'customer'
        );

        if ($terms === null || $privacy === null) {
            return response()->json([
                'message' => 'Los documentos legales vigentes no están disponibles.',
            ], 503);
        }

        if ((int) $validated['terms_document_id'] !== (int) $terms->id) {
            throw ValidationException::withMessages([
                'terms_document_id' => [
                    'La versión de los Términos y Condiciones ya no está vigente.',
                ],
            ]);
        }

        if (! $this->legalDocumentService->checksumMatches(
            $terms,
            $validated['terms_checksum']
        )) {
            throw ValidationException::withMessages([
                'terms_checksum' => [
                    'La versión de los Términos y Condiciones no coincide con la versión publicada.',
                ],
            ]);
        }

        if ((int) $validated['privacy_document_id'] !== (int) $privacy->id) {
            throw ValidationException::withMessages([
                'privacy_document_id' => [
                    'La versión de la Política de Privacidad ya no está vigente.',
                ],
            ]);
        }

        if (! $this->legalDocumentService->checksumMatches(
            $privacy,
            $validated['privacy_checksum']
        )) {
            throw ValidationException::withMessages([
                'privacy_checksum' => [
                    'La versión de la Política de Privacidad no coincide con la versión publicada.',
                ],
            ]);
        }

        DB::transaction(function () use (
            $request,
            $user,
            $validated,
            $terms,
            $privacy
        ): void {
            $user->forceFill([
                'birth_date' => $validated['birth_date'],
            ])->save();

            $this->legalAcceptanceService->acceptForUser(
                user: $user,
                documentId: $terms->id,
                checksum: $terms->checksum,
                request: $request,
                context: [
                    'metadata' => [
                        'source' => 'social_legal_onboarding',
                        'acceptance_kind' => 'contract_acceptance',
                    ],
                ]
            );

            $this->legalAcceptanceService->acceptForUser(
                user: $user,
                documentId: $privacy->id,
                checksum: $privacy->checksum,
                request: $request,
                context: [
                    'metadata' => [
                        'source' => 'social_legal_onboarding',
                        'acceptance_kind' => 'privacy_acknowledgement',
                    ],
                ]
            );
        });

        $user->refresh();

        return response()->json([
            'message' => 'Tu información legal fue completada correctamente.',
            'requires_legal_onboarding' => ! $this->onboardingService
                ->isComplete($user),

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