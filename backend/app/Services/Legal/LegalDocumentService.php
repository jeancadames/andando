<?php

namespace App\Services\Legal;

use App\Models\LegalDocument;
use Illuminate\Database\Eloquent\Collection;

class LegalDocumentService
{
    /**
     * Obtiene el documento vigente de un tipo y audiencia determinados.
     */
    public function current(
        string $type,
        string $audience
    ): ?LegalDocument {
        return LegalDocument::query()
            ->where('type', $type)
            ->where('audience', $audience)
            ->where('is_active', true)
            ->where('effective_at', '<=', now())
            ->where(function ($query) {
                $query
                    ->whereNull('published_at')
                    ->orWhere('published_at', '<=', now());
            })
            ->orderByDesc('effective_at')
            ->orderByDesc('id')
            ->first();
    }

    /**
     * Obtiene todos los documentos vigentes para una audiencia.
     */
    public function currentForAudience(
        string $audience
    ): Collection {
        return LegalDocument::query()
            ->where('audience', $audience)
            ->where('is_active', true)
            ->where('effective_at', '<=', now())
            ->where(function ($query) {
                $query
                    ->whereNull('published_at')
                    ->orWhere('published_at', '<=', now());
            })
            ->orderBy('type')
            ->orderByDesc('effective_at')
            ->orderByDesc('id')
            ->get()
            ->unique('type')
            ->values();
    }

    /**
     * Obtiene un documento vigente por su ID y valida su integridad.
     */
    public function findCurrentById(
        int $documentId
    ): ?LegalDocument {
        $document = LegalDocument::query()
            ->whereKey($documentId)
            ->where('is_active', true)
            ->where('effective_at', '<=', now())
            ->where(function ($query) {
                $query
                    ->whereNull('published_at')
                    ->orWhere('published_at', '<=', now());
            })
            ->first();

        if ($document === null) {
            return null;
        }

        return hash_equals(
            $document->checksum,
            LegalDocument::calculateChecksum($document->content)
        )
            ? $document
            : null;
    }

    /**
     * Comprueba que el checksum recibido coincide con el documento publicado.
     */
    public function checksumMatches(
        LegalDocument $document,
        string $checksum
    ): bool {
        return hash_equals(
            $document->checksum,
            $checksum
        );
    }
}