<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Legal\LegalAcceptanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LegalAcceptanceController extends Controller
{
    public function __construct(
        private readonly LegalAcceptanceService $legalAcceptanceService
    ) {
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'document_id' => [
                'required',
                'integer',
                'exists:legal_documents,id',
            ],
            'checksum' => [
                'required',
                'string',
                'size:64',
            ],
            'booking_id' => [
                'nullable',
                'integer',
                'exists:provider_bookings,id',
            ],
            'experience_id' => [
                'nullable',
                'integer',
                'exists:provider_experiences,id',
            ],
            'schedule_id' => [
                'nullable',
                'integer',
                'exists:provider_experience_schedules,id',
            ],
            'metadata' => [
                'nullable',
                'array',
            ],
            'metadata.minor_count' => [
                'nullable',
                'integer',
                'min:1',
            ],
        ]);

        $acceptance = $this->legalAcceptanceService
            ->acceptForUser(
                user: $request->user(),
                documentId: $validated['document_id'],
                checksum: $validated['checksum'],
                request: $request,
                context: [
                    'booking_id' => $validated['booking_id'] ?? null,
                    'experience_id' => $validated['experience_id'] ?? null,
                    'schedule_id' => $validated['schedule_id'] ?? null,
                    'metadata' => $validated['metadata'] ?? null,
                ]
            );

        return response()->json([
            'message' => 'Documento legal aceptado correctamente.',
            'data' => [
                'id' => $acceptance->id,
                'document_id' => $acceptance->legal_document_id,
                'accepted_at' => $acceptance->accepted_at
                    ?->toIso8601String(),
                'document_checksum' => $acceptance->document_checksum,
            ],
        ], 201);
    }
}