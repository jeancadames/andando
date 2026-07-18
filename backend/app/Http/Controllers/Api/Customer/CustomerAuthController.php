<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\CustomerRegisterRequest;
use App\Models\LegalDocument;
use App\Models\User;
use App\Notifications\Auth\WelcomeCustomerNotification;
use App\Services\Legal\LegalAcceptanceService;
use App\Services\Legal\LegalDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class CustomerAuthController extends Controller
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService,
        private readonly LegalAcceptanceService $legalAcceptanceService
    ) {
    }

    public function register(
        CustomerRegisterRequest $request
    ): JsonResponse {
        $validated = $request->validated();

        $termsDocument = $this->validateCurrentDocument(
            field: 'terms_document_id',
            expectedType: 'terms_user',
            documentId: $validated['terms_document_id'],
            checksum: $validated['terms_checksum']
        );

        $privacyDocument = $this->validateCurrentDocument(
            field: 'privacy_document_id',
            expectedType: 'privacy',
            documentId: $validated['privacy_document_id'],
            checksum: $validated['privacy_checksum']
        );

        $result = DB::transaction(function () use (
            $request,
            $validated,
            $termsDocument,
            $privacyDocument
        ): array {
            $user = User::query()->create([
                'name' => $validated['full_name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'birth_date' => $validated['birth_date'],
                'type' => 'customer',
                'password' => Hash::make($validated['password']),
            ]);

            $termsAcceptance = $this->legalAcceptanceService
                ->acceptForUser(
                    user: $user,
                    documentId: $termsDocument->id,
                    checksum: $termsDocument->checksum,
                    request: $request,
                    context: [
                        'metadata' => [
                            'source' => 'customer_registration',
                            'acceptance_kind' => 'contract_acceptance',
                        ],
                    ]
                );

            $privacyAcknowledgement = $this->legalAcceptanceService
                ->acceptForUser(
                    user: $user,
                    documentId: $privacyDocument->id,
                    checksum: $privacyDocument->checksum,
                    request: $request,
                    context: [
                        'metadata' => [
                            'source' => 'customer_registration',
                            'acceptance_kind' => 'privacy_acknowledgement',
                        ],
                    ]
                );

            $token = $user
                ->createToken('customer-mobile')
                ->plainTextToken;

            return [
                'user' => $user,
                'token' => $token,
                'terms_acceptance' => $termsAcceptance,
                'privacy_acknowledgement' => $privacyAcknowledgement,
            ];
        });

        $result['user']->notify(
            new WelcomeCustomerNotification()
        );

        return response()->json([
            'message' => 'Cuenta de cliente creada correctamente.',
            'token' => $result['token'],
            'user' => [
                'id' => $result['user']->id,
                'name' => $result['user']->name,
                'email' => $result['user']->email,
                'phone' => $result['user']->phone,
                'birth_date' => $result['user']
                    ->birth_date
                    ?->format('Y-m-d'),
                'type' => $result['user']->type,
            ],
            'legal' => [
                'terms' => [
                    'document_id' => $termsDocument->id,
                    'version' => $termsDocument->version,
                    'checksum' => $termsDocument->checksum,
                    'accepted_at' => $result['terms_acceptance']
                        ->accepted_at
                        ?->toIso8601String(),
                ],
                'privacy' => [
                    'document_id' => $privacyDocument->id,
                    'version' => $privacyDocument->version,
                    'checksum' => $privacyDocument->checksum,
                    'acknowledged_at' => $result[
                        'privacy_acknowledgement'
                    ]->accepted_at?->toIso8601String(),
                ],
            ],
        ], 201);
    }

    private function validateCurrentDocument(
        string $field,
        string $expectedType,
        int $documentId,
        string $checksum
    ): LegalDocument {
        $document = $this->legalDocumentService->current(
            $expectedType,
            'customer'
        );

        if ($document === null) {
            throw ValidationException::withMessages([
                $field => [
                    'El documento legal requerido no está disponible.',
                ],
            ]);
        }

        if ($document->id !== $documentId) {
            throw ValidationException::withMessages([
                $field => [
                    'El documento legal cambió. Revísalo nuevamente antes de continuar.',
                ],
            ]);
        }

        if (! $this->legalDocumentService->checksumMatches(
            $document,
            $checksum
        )) {
            $checksumField = $expectedType === 'terms_user'
                ? 'terms_checksum'
                : 'privacy_checksum';

            throw ValidationException::withMessages([
                $checksumField => [
                    'El documento legal cambió. Revísalo nuevamente antes de continuar.',
                ],
            ]);
        }

        return $document;
    }
}