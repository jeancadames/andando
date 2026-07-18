<?php

namespace App\Services\Legal;

use App\Models\LegalAcceptance;
use App\Models\LegalDocument;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class LegalAcceptanceService
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService
    ) {
    }

    public function acceptForUser(
        User $user,
        int $documentId,
        string $checksum,
        Request $request,
        array $context = []
    ): LegalAcceptance {
        $document = $this->legalDocumentService
            ->findCurrentById($documentId);

        if ($document === null) {
            throw ValidationException::withMessages([
                'document_id' => [
                    'El documento legal indicado no está vigente o no superó la validación de integridad.',
                ],
            ]);
        }

        if ($document->audience !== 'customer') {
            throw ValidationException::withMessages([
                'document_id' => [
                    'El documento indicado no corresponde a usuarios clientes.',
                ],
            ]);
        }

        if (! $this->legalDocumentService->checksumMatches(
            $document,
            $checksum
        )) {
            throw ValidationException::withMessages([
                'checksum' => [
                    'La versión del documento legal no coincide con la versión publicada.',
                ],
            ]);
        }

        $this->validateContext(
            $document,
            $context
        );

        return DB::transaction(function () use (
            $user,
            $document,
            $request,
            $context
        ): LegalAcceptance {
            $acceptance = LegalAcceptance::query()
                ->where('user_id', $user->id)
                ->where('legal_document_id', $document->id)
                ->where('document_checksum', $document->checksum)
                ->latest('accepted_at')
                ->first();

            if ($acceptance !== null) {
                return $acceptance;
            }

            return LegalAcceptance::query()->create([
                'legal_document_id' => $document->id,
                'user_id' => $user->id,
                'provider_id' => null,
                'booking_id' => $context['booking_id'] ?? null,
                'experience_id' => $context['experience_id'] ?? null,
                'schedule_id' => $context['schedule_id'] ?? null,
                'accepted_at' => now(),
                'document_checksum' => $document->checksum,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'platform' => $this->sanitizeNullableString(
                    $request->header('X-Platform')
                ),
                'app_version' => $this->sanitizeNullableString(
                    $request->header('X-App-Version')
                ),
                'locale' => $this->resolveLocale($request),
                'metadata' => $context['metadata'] ?? null,
            ]);
        });
    }

    private function validateContext(
        LegalDocument $document,
        array $context
    ): void {
        if (in_array($document->type, [
            'waiver',
            'minors',
        ], true)) {
            foreach ([
                'booking_id',
                'experience_id',
                'schedule_id',
            ] as $field) {
                if (empty($context[$field])) {
                    throw ValidationException::withMessages([
                        $field => [
                            "El campo {$field} es obligatorio para este documento.",
                        ],
                    ]);
                }
            }
        }

        if (
            $document->type === 'minors'
            && empty($context['metadata']['minor_count'])
        ) {
            throw ValidationException::withMessages([
                'metadata.minor_count' => [
                    'La cantidad de menores es obligatoria para esta declaración.',
                ],
            ]);
        }
    }

    private function sanitizeNullableString(
        ?string $value
    ): ?string {
        if ($value === null) {
            return null;
        }

        $value = trim($value);

        if ($value === '') {
            return null;
        }

        return mb_substr($value, 0, 30);
    }

    private function resolveLocale(
        Request $request
    ): string {
        $locale = trim(
            (string) $request->header('X-Locale', 'es')
        );

        if ($locale === '') {
            return 'es';
        }

        return mb_substr($locale, 0, 10);
    }
}