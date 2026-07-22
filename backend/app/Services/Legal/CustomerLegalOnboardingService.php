<?php

namespace App\Services\Legal;

use App\Models\User;
use Carbon\CarbonInterface;

class CustomerLegalOnboardingService
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService
    ) {
    }

    public function isComplete(User $user): bool
    {
        if ($user->type !== 'customer') {
            return false;
        }

        if (! $this->hasValidAdultBirthDate($user)) {
            return false;
        }

        $terms = $this->legalDocumentService->current(
            'terms_user',
            'customer'
        );

        $privacy = $this->legalDocumentService->current(
            'privacy',
            'customer'
        );

        if ($terms === null || $privacy === null) {
            return false;
        }

        $acceptedDocumentIds = $user->legalAcceptances()
            ->whereIn('legal_document_id', [
                $terms->id,
                $privacy->id,
            ])
            ->whereIn('document_checksum', [
                $terms->checksum,
                $privacy->checksum,
            ])
            ->get([
                'legal_document_id',
                'document_checksum',
            ])
            ->mapWithKeys(fn ($acceptance) => [
                (int) $acceptance->legal_document_id
                    => $acceptance->document_checksum,
            ]);

        return hash_equals(
            $terms->checksum,
            (string) $acceptedDocumentIds->get($terms->id, '')
        ) && hash_equals(
            $privacy->checksum,
            (string) $acceptedDocumentIds->get($privacy->id, '')
        );
    }

    private function hasValidAdultBirthDate(User $user): bool
    {
        $birthDate = $user->birth_date;

        if (! $birthDate instanceof CarbonInterface) {
            return false;
        }

        return $birthDate->lte(
            now()->subYears(18)->startOfDay()
        );
    }
}