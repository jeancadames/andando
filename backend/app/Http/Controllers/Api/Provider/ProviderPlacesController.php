<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class ProviderPlacesController extends Controller
{
    public function search(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'q' => ['required', 'string', 'min:3', 'max:255'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:10'],
        ]);

        $query = trim($validated['q']);
        $limit = (int) ($validated['limit'] ?? 5);

        $cacheKey = 'nominatim_search_' . md5(
            mb_strtolower($query) . '|' . $limit
        );

        $results = Cache::remember($cacheKey, now()->addDays(7), function () use (
            $query,
            $limit
        ) {
            $baseUrl = rtrim(
                config('services.nominatim.base_url', 'https://nominatim.openstreetmap.org'),
                '/'
            );

            $response = Http::withHeaders([
                'User-Agent' => config('services.nominatim.user_agent', 'AndanDO/1.0'),
                'Accept' => 'application/json',
            ])
                ->timeout(12)
                ->get($baseUrl . '/search', [
                    'q' => $query,
                    'format' => 'jsonv2',
                    'addressdetails' => 1,
                    'limit' => $limit,
                    'countrycodes' => config('services.nominatim.country', 'do'),
                    'accept-language' => 'es',
                ]);

            if (! $response->successful()) {
                return [
                    'error' => true,
                    'status' => $response->status(),
                    'body' => $response->json(),
                ];
            }

            return collect($response->json())
                ->map(function ($place) {
                    return [
                        'place_id' => (string) ($place['place_id'] ?? ''),
                        'name' => $this->resolveName($place),
                        'address' => $place['display_name'] ?? '',
                        'latitude' => isset($place['lat'])
                            ? (float) $place['lat']
                            : null,
                        'longitude' => isset($place['lon'])
                            ? (float) $place['lon']
                            : null,
                        'type' => $place['type'] ?? null,
                        'category' => $place['category'] ?? null,
                    ];
                })
                ->filter(function ($place) {
                    return ! empty($place['name']) &&
                        ! empty($place['address']) &&
                        $place['latitude'] !== null &&
                        $place['longitude'] !== null;
                })
                ->values()
                ->all();
        });

        if (is_array($results) && ($results['error'] ?? false)) {
            return response()->json([
                'message' => 'No se pudieron buscar ubicaciones.',
                'status' => $results['status'] ?? null,
                'details' => $results['body'] ?? null,
            ], 502);
        }

        return response()->json([
            'data' => $results,
            'attribution' => '© OpenStreetMap contributors',
        ]);
    }

    private function resolveName(array $place): string
    {
        $named = trim((string) ($place['name'] ?? ''));

        if ($named !== '') {
            return $named;
        }

        $address = $place['address'] ?? [];

        foreach ([
            'tourism',
            'amenity',
            'building',
            'road',
            'suburb',
            'neighbourhood',
            'city',
            'town',
            'village',
        ] as $key) {
            if (! empty($address[$key])) {
                return (string) $address[$key];
            }
        }

        $displayName = (string) ($place['display_name'] ?? '');

        if ($displayName !== '') {
            return explode(',', $displayName)[0] ?? $displayName;
        }

        return 'Ubicación seleccionada';
    }
}