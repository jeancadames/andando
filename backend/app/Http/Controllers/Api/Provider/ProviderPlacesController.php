<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Throwable;

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
        $apiKey = trim((string) config('services.google_places.api_key'));

        if ($apiKey === '') {
            return response()->json([
                'message' => 'La busqueda de ubicaciones no esta configurada.',
            ], 503);
        }

        try {
            $baseUrl = rtrim(
                (string) config(
                    'services.google_places.base_url',
                    'https://places.googleapis.com'
                ),
                '/'
            );

            $response = Http::withHeaders([
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'X-Goog-Api-Key' => $apiKey,
                'X-Goog-FieldMask' => implode(',', [
                    'places.id',
                    'places.displayName',
                    'places.formattedAddress',
                    'places.location',
                ]),
            ])
                ->timeout(12)
                ->post($baseUrl . '/v1/places:searchText', [
                    'textQuery' => $query,
                    'languageCode' => (string) config(
                        'services.google_places.language',
                        'es'
                    ),
                    'regionCode' => (string) config(
                        'services.google_places.region',
                        'DO'
                    ),
                    'pageSize' => $limit,
                ]);

            if (! $response->successful()) {
                throw new RuntimeException(
                    'Google Places respondio con HTTP ' . $response->status()
                );
            }

            $results = collect($response->json('places', []))
                ->map(function (array $place): array {
                    $displayName = $place['displayName']['text'] ?? '';
                    $address = $place['formattedAddress'] ?? '';
                    $location = $place['location'] ?? [];

                    return [
                        'place_id' => (string) ($place['id'] ?? ''),
                        'name' => trim((string) $displayName),
                        'address' => trim((string) $address),
                        'latitude' => isset($location['latitude'])
                            ? (float) $location['latitude']
                            : null,
                        'longitude' => isset($location['longitude'])
                            ? (float) $location['longitude']
                            : null,
                    ];
                })
                ->filter(function (array $place): bool {
                    return $place['name'] !== ''
                        && $place['address'] !== ''
                        && $place['latitude'] !== null
                        && $place['longitude'] !== null;
                })
                ->values()
                ->all();
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'message' => 'No se pudieron buscar ubicaciones en este momento.',
            ], 502);
        }

        return response()->json([
            'data' => $results,
            'attribution' => 'Google Maps',
        ]);
    }
}
