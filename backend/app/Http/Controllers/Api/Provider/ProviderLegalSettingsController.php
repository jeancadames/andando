<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\LegalAcceptance;
use App\Models\LegalDocument;
use App\Services\Legal\LegalDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProviderLegalSettingsController extends Controller
{
    public function __construct(
        private readonly LegalDocumentService $legalDocumentService
    ) {
    }

    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        $provider = $user?->provider;

        if (! $provider) {
            return response()->json([
                'message' => 'Este usuario no tiene un perfil de proveedor.',
                'data' => null,
            ], 403);
        }

        $documents = $this->legalDocumentService
            ->currentForAudience('provider');

        $documentIds = $documents->pluck('id');

        $acceptances = LegalAcceptance::query()
            ->where('user_id', $user->id)
            ->where('provider_id', $provider->id)
            ->whereIn('legal_document_id', $documentIds)
            ->with('legalDocument')
            ->latest('accepted_at')
            ->get()
            ->unique('legal_document_id')
            ->keyBy('legal_document_id');

        $formattedDocuments = $documents
            ->map(function (
                LegalDocument $document
            ) use ($acceptances): array {
                /** @var LegalAcceptance|null $acceptance */
                $acceptance = $acceptances->get($document->id);

                $checksumIsValid = $acceptance !== null
                    && hash_equals(
                        $document->checksum,
                        $acceptance->document_checksum
                    );

                $accepted = $acceptance !== null
                    && $checksumIsValid;

                return [
                    'id' => $document->id,
                    'type' => $document->type,
                    'audience' => $document->audience,
                    'version' => $document->version,
                    'title' => $document->title,
                    'summary' => $document->summary,
                    'content_format' => $document->content_format,
                    'effective_at' =>
                        $document->effective_at?->toIso8601String(),
                    'published_at' =>
                        $document->published_at?->toIso8601String(),
                    'requires_acceptance' =>
                        $document->requires_acceptance,
                    'acceptance_scope' => match ($document->type) {
                        'terms_provider',
                        'provider_standards' => 'provider_account',
                        'privacy' => 'provider_acknowledgement',
                        default => 'informational',
                    },
                    'change_level' => $document->change_level,
                    'checksum' => $document->checksum,
                    'accepted' => $accepted,
                    'accepted_at' => $accepted
                        ? $acceptance->accepted_at?->toIso8601String()
                        : null,
                    'accepted_label' => $accepted
                        ? $this->formatSpanishDate(
                            $acceptance->accepted_at
                        )
                        : null,
                    'status_label' => $this->resolveStatusLabel(
                        document: $document,
                        accepted: $accepted,
                    ),
                ];
            })
            ->values();

        $terms = $formattedDocuments->firstWhere(
            'type',
            'terms_provider'
        );

        $standards = $formattedDocuments->firstWhere(
            'type',
            'provider_standards'
        );

        $privacy = $formattedDocuments->firstWhere(
            'type',
            'privacy'
        );

        $requiresAction = $formattedDocuments->contains(
            fn (array $document): bool =>
                in_array(
                    $document['type'],
                    [
                        'terms_provider',
                        'provider_standards',
                    ],
                    true
                )
                && $document['requires_acceptance']
                && ! $document['accepted']
        );

        $acceptedRequiredCount = $formattedDocuments
            ->filter(
                fn (array $document): bool =>
                    $document['requires_acceptance']
                    && $document['accepted']
            )
            ->count();

        $requiredCount = $formattedDocuments
            ->filter(
                fn (array $document): bool =>
                    $document['requires_acceptance']
            )
            ->count();

        return response()->json([
            'message' =>
                'Configuración legal del proveedor obtenida correctamente.',
            'data' => [
                'requires_action' => $requiresAction,

                'summary' => [
                    'required_documents_count' => $requiredCount,
                    'accepted_required_documents_count' =>
                        $acceptedRequiredCount,
                    'all_required_documents_accepted' =>
                        ! $requiresAction,
                ],

                'documents' => $formattedDocuments,

                'terms' => $terms,
                'standards' => $standards,
                'privacy' => $privacy,

                'provider' => [
                    'id' => $provider->id,
                    'business_name' => $provider->business_name,
                    'status' => $provider->status,
                ],

                'contact' => [
                    'support_email' => 'soporte@andando.do',
                    'commercial_email' => 'comercial@andando.do',
                ],

                'corporate_notice' => [
                    'operator_name' =>
                        'ABC VANTEK GROUP, S.R.L.',
                    'status' => 'in_process',
                    'rnc' => null,
                    'commercial_registry' => null,
                    'footer' =>
                        'AndanDO — plataforma en proceso de ser operada por ABC VANTEK GROUP, S.R.L. • Santo Domingo, República Dominicana • Soporte: soporte@andando.do • Comercial: comercial@andando.do',
                ],
            ],
        ]);
    }

    private function resolveStatusLabel(
        LegalDocument $document,
        bool $accepted
    ): string {
        if ($accepted) {
            return match ($document->type) {
                'privacy' => 'Leído',
                'terms_provider',
                'provider_standards' => 'Aceptado',
                default => 'Registrado',
            };
        }

        return match ($document->type) {
            'terms_provider',
            'provider_standards' => 'Pendiente',
            'privacy' => 'Pendiente de lectura',
            default => 'Documento informativo',
        };
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