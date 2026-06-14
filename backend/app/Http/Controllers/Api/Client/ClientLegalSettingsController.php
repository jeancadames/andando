<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientLegalSettingsController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'message' => 'Configuración legal obtenida correctamente.',
            'data' => [
                'terms_accepted_at' => $user->created_at?->toIso8601String(),
                'terms_accepted_label' => $this->formatSpanishDate($user->created_at),
                'terms_version' => config('andando.legal.terms_version'),
                'privacy_version' => config('andando.legal.privacy_version'),
                'cookies_version' => config('andando.legal.cookies_version'),
                'rnc' => config('andando.legal.rnc'),
                'support_email' => config('andando.legal.support_email'),
            ],
        ]);
    }

    private function formatSpanishDate($date): ?string
    {
        if (! $date) {
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

        return $date->day . ' de ' . $months[(int) $date->month] . ' de ' . $date->year;
    }
}