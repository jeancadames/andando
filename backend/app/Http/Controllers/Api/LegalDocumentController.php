<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LegalDocument;
use App\Services\Legal\LegalDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LegalDocumentController extends Controller
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $audience = trim(
            (string) $request->query('audience', 'customer')
        );

        if (! in_array($audience, [
            'customer',
            'provider',
            'participant',
            'public',
        ], true)) {
            return response()->json([
                'message' => 'La audiencia legal indicada no es válida.',
                'data' => null,
            ], 422);
        }

        $documents = $this->legalDocumentService
            ->currentForAudience($audience)
            ->map(fn (LegalDocument $document) => $this->formatDocument(
                $document,
                includeContent: false
            ))
            ->values();

        return response()->json([
            'message' => 'Documentos legales obtenidos correctamente.',
            'data' => $documents,
        ]);
    }

    public function show(
        Request $request,
        string $type
    ): JsonResponse {
        $audience = trim(
            (string) $request->query('audience', 'customer')
        );

        if (! in_array($audience, [
            'customer',
            'provider',
            'participant',
            'public',
        ], true)) {
            return response()->json([
                'message' => 'La audiencia legal indicada no es válida.',
                'data' => null,
            ], 422);
        }

        $document = $this->legalDocumentService->current(
            $type,
            $audience
        );

        if ($document === null) {
            return response()->json([
                'message' => 'Documento legal no encontrado.',
                'data' => null,
            ], 404);
        }

        if (! hash_equals(
            $document->checksum,
            LegalDocument::calculateChecksum($document->content)
        )) {
            return response()->json([
                'message' => 'El documento legal no superó la validación de integridad.',
                'data' => null,
            ], 409);
        }

        return response()->json([
            'message' => 'Documento legal obtenido correctamente.',
            'data' => $this->formatDocument(
                $document,
                includeContent: true
            ),
        ]);
    }

    private function formatDocument(
        LegalDocument $document,
        bool $includeContent
    ): array {
        $data = [
            'id' => $document->id,
            'type' => $document->type,
            'audience' => $document->audience,
            'version' => $document->version,
            'title' => $document->title,
            'summary' => $document->summary,
            'content_format' => $document->content_format,
            'effective_at' => $document->effective_at?->toIso8601String(),
            'published_at' => $document->published_at?->toIso8601String(),
            'requires_acceptance' => $document->requires_acceptance,
            'change_level' => $document->change_level,
            'checksum' => $document->checksum,
        ];

        if ($includeContent) {
            $data['content'] = $document->content;
        }

        return $data;
    }
}