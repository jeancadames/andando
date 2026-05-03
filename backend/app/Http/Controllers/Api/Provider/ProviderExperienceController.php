<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\ProviderExperience;
use App\Models\ProviderExperiencePhoto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ProviderExperienceController extends Controller
{
    /**
     * Lista experiencias reales del afiliado autenticado.
     *
     * Soporta:
     * - ?status=published
     * - ?status=draft
     */
    public function index(Request $request): JsonResponse
    {
        $provider = $request->user();

        $status = $request->query('status');

        $query = ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->with('coverPhoto')
            ->withCount([
                'schedules as schedules_count' => function ($query) {
                    $query->where('status', 'active')
                        ->where('starts_at', '>=', now());
                },
                'bookings as bookings_count' => function ($query) {
                    $query->whereIn('status', ['confirmed', 'completed']);
                },
            ])
            ->withSum([
                'bookings as revenue' => function ($query) {
                    $query->whereIn('status', ['confirmed', 'completed']);
                },
            ], 'provider_earning')
            ->withAvg([
                'reviews as rating' => function ($query) {
                    $query->where('is_visible', true);
                },
            ], 'rating')
            ->withMin([
                'schedules as next_available' => function ($query) {
                    $query->where('status', 'active')
                        ->where('starts_at', '>=', now());
                },
            ], 'starts_at')
            ->latest();

        if ($status) {
            $query->where('status', $status);
        }

        $experiences = $query->get()->map(function (ProviderExperience $experience) {
            return $this->formatExperience($experience);
        });

        return response()->json([
            'data' => $experiences,
        ]);
    }

    /**
     * Crea una experiencia.
     *
     * Para guardar borrador:
     * publish=false
     *
     * Para crear y publicar de una vez:
     * publish=true
     */
    public function store(Request $request): JsonResponse
    {
        $provider = $request->user();
        $publishing = $request->boolean('publish');

        $validated = $this->validateExperience($request, $publishing);

        return DB::transaction(function () use ($provider, $validated, $request, $publishing) {
            $experience = ProviderExperience::create([
                ...$this->experiencePayload($validated),
                'provider_id' => $provider->id,
                'status' => $publishing ? 'published' : 'draft',
                'published_at' => $publishing ? now() : null,
                'is_active' => true,
            ]);

            $this->storePhotos($request, $experience);

            if ($publishing) {
                $this->ensurePublishable($experience->fresh(['photos']));
            }

            return response()->json([
                'message' => $publishing
                    ? 'Experiencia publicada correctamente.'
                    : 'Borrador guardado correctamente.',
                'data' => $this->formatExperience($experience->fresh(['photos', 'coverPhoto'])),
            ], 201);
        });
    }

    public function show(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $experience->load(['photos', 'coverPhoto']);

        return response()->json([
            'data' => $this->formatExperience($experience),
        ]);
    }

    /**
     * Actualiza una experiencia existente.
     *
     * Enviar como multipart:
     * POST /api/provider/experiences/{id}
     */
    public function update(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $publishing = $request->boolean('publish');

        $validated = $this->validateExperience($request, $publishing, $experience);

        return DB::transaction(function () use ($request, $experience, $validated, $publishing) {
            $experience->update([
                ...$this->experiencePayload($validated),
                'status' => $publishing ? 'published' : $experience->status,
                'published_at' => $publishing && ! $experience->published_at
                    ? now()
                    : $experience->published_at,
            ]);

            $this->storePhotos($request, $experience);

            if ($publishing) {
                $this->ensurePublishable($experience->fresh(['photos']));
            }

            return response()->json([
                'message' => $publishing
                    ? 'Experiencia actualizada y publicada correctamente.'
                    : 'Experiencia actualizada correctamente.',
                'data' => $this->formatExperience($experience->fresh(['photos', 'coverPhoto'])),
            ]);
        });
    }

    /**
     * Publica una experiencia ya guardada como borrador.
     */
    public function publish(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $experience->load('photos');

        $this->ensurePublishable($experience);

        $experience->update([
            'status' => 'published',
            'published_at' => $experience->published_at ?? now(),
            'is_active' => true,
        ]);

        return response()->json([
            'message' => 'Experiencia publicada correctamente.',
            'data' => $this->formatExperience($experience->fresh(['photos', 'coverPhoto'])),
        ]);
    }

    /**
     * Pausa una experiencia publicada.
     */
    public function pause(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $experience->update([
            'status' => 'paused',
        ]);

        return response()->json([
            'message' => 'Experiencia pausada correctamente.',
            'data' => $this->formatExperience($experience->fresh(['coverPhoto'])),
        ]);
    }

    /**
     * Eliminación lógica.
     *
     * No borra de la base de datos.
     * Esto evita romper reservas, estadísticas y auditoría.
     */
    public function destroy(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $experience->delete();

        return response()->json([
            'message' => 'Experiencia eliminada correctamente.',
        ]);
    }

    private function validateExperience(Request $request, bool $publishing, ?ProviderExperience $experience = null): array
    {
        $requiredIfPublishing = $publishing ? 'required' : 'nullable';

        return $request->validate([
            'title' => [$requiredIfPublishing, 'string', 'max:160'],
            'category' => [$requiredIfPublishing, 'string', 'max:80'],
            'description' => [$requiredIfPublishing, 'string'],
            'duration' => [$requiredIfPublishing, 'string', 'max:80'],

            'capacity' => [$requiredIfPublishing, 'integer', 'min:1', 'max:500'],
            'maxCapacity' => ['nullable', 'integer', 'min:1', 'max:500'],

            'price' => [$requiredIfPublishing, 'numeric', 'min:0', 'max:99999999.99'],
            'currency' => ['nullable', 'string', Rule::in(['DOP', 'USD'])],

            'location' => ['nullable', 'string', 'max:255'],
            'province' => [$requiredIfPublishing, 'string', 'max:100'],
            'start_location' => ['nullable', 'string'],
            'startLocation' => ['nullable', 'string'],

            'pickup_points' => [$requiredIfPublishing, 'array'],
            'pickup_points.*' => ['nullable', 'string', 'max:255'],

            'itinerary' => [$requiredIfPublishing, 'array'],
            'itinerary.*.time' => ['nullable', 'string', 'max:20'],
            'itinerary.*.activity' => ['nullable', 'string', 'max:255'],

            'amenities' => ['nullable', 'array'],
            'amenities.*' => ['nullable', 'string', 'max:100'],

            'included' => [$requiredIfPublishing, 'array'],
            'included.*' => ['nullable', 'string', 'max:255'],

            'not_included' => ['nullable', 'array'],
            'not_included.*' => ['nullable', 'string', 'max:255'],

            'requirements' => ['nullable', 'array'],
            'requirements.*' => ['nullable', 'string', 'max:255'],

            'cancellation_policy' => [$requiredIfPublishing, 'string', 'max:80'],
            'cancellationPolicy' => ['nullable', 'string', 'max:80'],

            'photos' => ['nullable', 'array', 'max:10'],
            'photos.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
    }

    private function experiencePayload(array $validated): array
    {
        return [
            'title' => $validated['title'] ?? null,
            'category' => $validated['category'] ?? null,
            'description' => $validated['description'] ?? null,
            'duration' => $validated['duration'] ?? null,
            'location' => $validated['location'] ?? null,
            'province' => $validated['province'] ?? null,
            'start_location' => $validated['start_location'] ?? $validated['startLocation'] ?? null,
            'pickup_points' => $this->cleanArray($validated['pickup_points'] ?? []),
            'price' => $validated['price'] ?? 0,
            'currency' => $validated['currency'] ?? 'DOP',
            'capacity' => $validated['capacity'] ?? $validated['maxCapacity'] ?? 1,
            'itinerary' => $this->cleanItinerary($validated['itinerary'] ?? []),
            'amenities' => $this->cleanArray($validated['amenities'] ?? []),
            'included' => $this->cleanArray($validated['included'] ?? []),
            'not_included' => $this->cleanArray($validated['not_included'] ?? []),
            'requirements' => $this->cleanArray($validated['requirements'] ?? []),
            'cancellation_policy' => $validated['cancellation_policy'] ?? $validated['cancellationPolicy'] ?? null,
        ];
    }

    private function storePhotos(Request $request, ProviderExperience $experience): void
    {
        if (! $request->hasFile('photos')) {
            return;
        }

        $currentMaxOrder = (int) $experience->photos()->max('sort_order');
        $hasCover = $experience->photos()->where('is_cover', true)->exists();

        foreach ($request->file('photos') as $index => $photo) {
            $path = $photo->store(
                "provider-experiences/provider_{$experience->provider_id}/experience_{$experience->id}",
                'public'
            );

            ProviderExperiencePhoto::create([
                'provider_experience_id' => $experience->id,
                'path' => $path,
                'original_name' => $photo->getClientOriginalName(),
                'mime_type' => $photo->getMimeType(),
                'size_bytes' => $photo->getSize(),
                'sort_order' => $currentMaxOrder + $index + 1,
                'is_cover' => ! $hasCover && $index === 0,
            ]);
        }
    }

    private function ensurePublishable(ProviderExperience $experience): void
    {
        $missing = [];

        foreach ([
            'title',
            'category',
            'description',
            'duration',
            'province',
            'start_location',
            'price',
            'capacity',
            'cancellation_policy',
        ] as $field) {
            if (blank($experience->{$field})) {
                $missing[] = $field;
            }
        }

        if (count($experience->pickup_points ?? []) < 1) {
            $missing[] = 'pickup_points';
        }

        if (count($experience->itinerary ?? []) < 2) {
            $missing[] = 'itinerary';
        }

        if (count($experience->included ?? []) < 1) {
            $missing[] = 'included';
        }

        if ($experience->photos()->count() < 3) {
            $missing[] = 'photos';
        }

        if (! empty($missing)) {
            abort(response()->json([
                'message' => 'La experiencia no puede publicarse porque faltan campos obligatorios.',
                'missing_fields' => $missing,
            ], 422));
        }
    }

    private function authorizeProvider(Request $request, ProviderExperience $experience): void
    {
        if ((int) $experience->provider_id !== (int) $request->user()->id) {
            abort(403, 'No tienes permiso para modificar esta experiencia.');
        }
    }

    private function cleanArray(array $items): array
    {
        return collect($items)
            ->filter(fn ($item) => filled($item))
            ->values()
            ->all();
    }

    private function cleanItinerary(array $items): array
    {
        return collect($items)
            ->filter(fn ($item) => filled($item['time'] ?? null) || filled($item['activity'] ?? null))
            ->values()
            ->all();
    }

    private function formatExperience(ProviderExperience $experience): array
    {
        $coverPhoto = $experience->coverPhoto;

        return [
            'id' => $experience->id,
            'title' => $experience->title,
            'category' => $experience->category,
            'description' => $experience->description,
            'duration' => $experience->duration,
            'location' => $experience->location,
            'province' => $experience->province,
            'start_location' => $experience->start_location,
            'pickup_points' => $experience->pickup_points ?? [],
            'price' => (float) $experience->price,
            'currency' => $experience->currency,
            'capacity' => $experience->capacity,
            'itinerary' => $experience->itinerary ?? [],
            'amenities' => $experience->amenities ?? [],
            'included' => $experience->included ?? [],
            'not_included' => $experience->not_included ?? [],
            'requirements' => $experience->requirements ?? [],
            'cancellation_policy' => $experience->cancellation_policy,
            'status' => $experience->status,
            'is_active' => $experience->is_active,
            'published_at' => optional($experience->published_at)->toISOString(),

            'cover_photo_url' => $coverPhoto
                ? asset('storage/' . ltrim($coverPhoto->path, '/'))
                : null,

            'photos' => $experience->relationLoaded('photos')
                ? $experience->photos->map(fn ($photo) => [
                    'id' => $photo->id,
                    'url' => asset('storage/' . ltrim($coverPhoto->path, '/')),
                    'is_cover' => $photo->is_cover,
                    'sort_order' => $photo->sort_order,
                ])->values()
                : [],

            'bookings_count' => (int) ($experience->bookings_count ?? 0),
            'revenue' => (float) ($experience->revenue ?? 0),
            'views' => 0,
            'rating' => $experience->rating ? round((float) $experience->rating, 1) : 0,
            'schedules_count' => (int) ($experience->schedules_count ?? 0),
            'next_available' => $experience->next_available,
        ];
    }
}