<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\LegalAcceptance;
use App\Models\LegalDocument;
use App\Services\Legal\LegalDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientLegalSettingsController extends Controller
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService
    ) {
    }

    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        $documents = $this->legalDocumentService
            ->currentForAudience('customer');

        $documentIds = $documents->pluck('id');

        $acceptances = LegalAcceptance::query()
            ->where('user_id', $user->id)
            ->whereIn('legal_document_id', $documentIds)
            ->with('legalDocument')
            ->latest('accepted_at')
            ->get()
            ->unique('legal_document_id')
            ->keyBy('legal_document_id');

        $formattedDocuments = $documents
            ->map(function (LegalDocument $document) use ($acceptances): array {
                /** @var LegalAcceptance|null $acceptance */
                $acceptance = $acceptances->get($document->id);

                $checksumIsValid = $acceptance !== null
                    && hash_equals(
                        $document->checksum,
                        $acceptance->document_checksum
                    );

                $accepted = $acceptance !== null && $checksumIsValid;

                return [
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
                    'accepted' => $accepted,
                    'accepted_at' => $accepted
                        ? $acceptance->accepted_at?->toIso8601String()
                        : null,
                    'accepted_label' => $accepted
                        ? $this->formatSpanishDate($acceptance->accepted_at)
                        : null,
                ];
            })
            ->values();

        $terms = $formattedDocuments->firstWhere(
            'type',
            'terms_user'
        );

        $privacy = $formattedDocuments->firstWhere(
            'type',
            'privacy'
        );

        $cookies = $formattedDocuments->firstWhere(
            'type',
            'cookies'
        );

        $requiresAction = $formattedDocuments->contains(
            fn (array $document): bool =>
                $document['requires_acceptance']
                && ! $document['accepted']
        );

        return response()->json([
            'message' => 'Configuración legal obtenida correctamente.',
            'data' => [
                'requires_action' => $requiresAction,
                'documents' => $formattedDocuments,
                'terms' => $terms,
                'privacy' => $privacy,
                'cookies' => $cookies,
                'contact' => [
                    'support_email' => 'soporte@andando.do',
                    'commercial_email' => 'comercial@andando.do',
                ],
                'corporate_notice' => [
                    'operator_name' => 'ABC VANTEK GROUP, S.R.L.',
                    'status' => 'in_process',
                    'rnc' => null,
                    'commercial_registry' => null,
                    'footer' => 'AndanDO — plataforma en proceso de ser operada por ABC VANTEK GROUP, S.R.L. • Santo Domingo, República Dominicana • Soporte: soporte@andando.do • Comercial: comercial@andando.do',
                ],
            ],
        ]);
    }

    private function formatSpanishDate($date): ?string
    {
        if ($date === null) {
            return null;
        }

        $months = [
            1 => 'enero',
            2 => 'febrero',
            3 => 'marzo',
            4 => 'abril',
            5 => 'mayo',
            6 => 'junio',
            7 => 'julio',
            8 => 'agosto',
            9 => 'septiembre',
            10 => 'octubre',
            11 => 'noviembre',
            12 => 'diciembre',
        ];

        return $date->day
            . ' de '
            . $months[(int) $date->month]
            . ' de '
            . $date->year;
    }
}