<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProviderPricingSettingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $commissionRate = (float) config('andando.commission_rate', 0.15);

        if ($commissionRate < 0) {
            $commissionRate = 0;
        }

        if ($commissionRate > 1) {
            $commissionRate = 1;
        }

        return response()->json([
            'data' => [
                'commission_rate' => $commissionRate,
                'commission_percentage' => round($commissionRate * 100, 2),
                'currency' => 'DOP',
            ],
        ]);
    }
}