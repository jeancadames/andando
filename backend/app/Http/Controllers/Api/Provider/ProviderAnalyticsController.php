<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Services\Provider\ProviderAnalyticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProviderAnalyticsController extends Controller
{
    public function __construct(
        private readonly ProviderAnalyticsService $analyticsService,
    ) {
    }

    /**
     * Endpoint principal de análisis estadístico del afiliado.
     *
     * Ruta:
     * GET /api/provider/analytics
     *
     * Filtros:
     * - period=7d
     * - period=30d
     * - period=90d
     * - period=year
     * - period=custom&start_date=2026-01-01&end_date=2026-12-31
     * - experience_id=1
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'message' => 'No autenticado.',
            ], 401);
        }

        $provider = $user->provider;

        if (! $provider) {
            return response()->json([
                'message' => 'Este usuario no tiene perfil de proveedor.',
            ], 403);
        }

        if ($provider->status !== 'approved') {
            return response()->json([
                'message' => 'El dashboard de análisis solo está disponible para proveedores aprobados.',
                'provider_status' => $provider->status,
            ], 403);
        }

        $validated = $request->validate([
            'period' => ['nullable', 'string', 'in:7d,30d,90d,year,custom'],
            'start_date' => ['nullable', 'date', 'required_if:period,custom'],
            'end_date' => ['nullable', 'date', 'required_if:period,custom', 'after_or_equal:start_date'],
            'experience_id' => ['nullable', 'integer'],
        ]);

        $analytics = $this->analyticsService->getAnalytics(
            user: $user,
            filters: $validated,
        );

        return response()->json($analytics);
    }
}