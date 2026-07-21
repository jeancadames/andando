<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProviderPricingSettingController extends Controller
{
    /** AndanDO Provider Commissions Module */
    public function index(Request $request): JsonResponse
    {
        $provider = $request->user()?->provider;

        if (! $provider) {
            abort(404, 'No se encontró el perfil del afiliado.');
        }

        $commissionRate = $provider->commissionRate();

        return response()->json([
            'data' => [
                'commission_rate' => $commissionRate,
                'commission_percentage' => round($commissionRate * 100, 2),
                'currency' => 'DOP',
            ],
        ]);
    }
}
