<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\Provider;
use App\Models\ProviderExperience;
use App\Models\ProviderExperiencePhoto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ProviderExperienceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $status = $request->query('status');

        $query = ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->with(['coverPhoto', 'photos', 'mapPickupPoints'])
            ->withCount([
                'schedules as schedules_count' => function ($query) {
                    $query->where('status', 'active')
                        ->where('starts_at', '>=', now());
                },
            ])
            ->withSum([
                'bookings as bookings_count' => function ($query) {
                    $query->whereNotIn('status', [
                        'cancelled',
                        'canceled',
                        'rejected',
                    ]);
                },
            ], 'guests_count')
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

    public function store(Request $request): JsonResponse
    {
        $provider = $this->currentProvider($request);
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

            $this->syncMapPickupPoints(
                $experience,
                $validated['map_pickup_points'] ?? []
            );

            if ($publishing) {
                $this->ensurePublishable($experience->fresh(['photos']));
            }

            return response()->json([
                'message' => $publishing
                    ? 'Experiencia publicada correctamente.'
                    : 'Borrador guardado correctamente.',
                'data' => $this->formatExperience(
                    $experience->fresh(['photos', 'coverPhoto', 'mapPickupPoints'])
                ),
            ], 201);
        });
    }

    public function show(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $experience->load(['photos', 'coverPhoto', 'mapPickupPoints']);

        return response()->json([
            'data' => $this->formatExperience($experience),
        ]);
    }

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

            if ($request->has('map_pickup_points')) {
                $this->syncMapPickupPoints(
                    $experience,
                    $validated['map_pickup_points'] ?? []
                );
            }

            if ($publishing) {
                $this->ensurePublishable($experience->fresh(['photos']));
            }

            return response()->json([
                'message' => $publishing
                    ? 'Experiencia actualizada y publicada correctamente.'
                    : 'Experiencia actualizada correctamente.',
                'data' => $this->formatExperience(
                    $experience->fresh(['photos', 'coverPhoto', 'mapPickupPoints'])
                ),
            ]);
        });
    }

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
            'data' => $this->formatExperience(
                $experience->fresh(['photos', 'coverPhoto', 'mapPickupPoints'])
            ),
        ]);
    }

    public function pause(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $experience->update([
            'status' => 'paused',
        ]);

        return response()->json([
            'message' => 'Experiencia pausada correctamente.',
            'data' => $this->formatExperience(
                $experience->fresh(['coverPhoto', 'photos', 'mapPickupPoints'])
            ),
        ]);
    }

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
            'title' => ['required', 'string', 'max:160'],
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

            'experience_address' => ['nullable', 'string', 'max:255'],
            'experience_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'experience_longitude' => ['nullable', 'numeric', 'between:-180,180'],

            'pickup_points' => [$requiredIfPublishing, 'array'],
            'pickup_points.*' => ['nullable', 'string', 'max:255'],

            'map_pickup_points' => ['nullable', 'array'],
            'map_pickup_points.*.name' => ['nullable', 'string', 'max:255'],
            'map_pickup_points.*.address' => ['nullable', 'string', 'max:500'],
            'map_pickup_points.*.latitude' => ['required', 'numeric', 'between:-90,90'],
            'map_pickup_points.*.longitude' => ['required', 'numeric', 'between:-180,180'],
            'map_pickup_points.*.instructions' => ['nullable', 'string', 'max:1000'],

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
            'title' => $validated['title'] ?? 'Borrador sin título',
            'category' => $validated['category'] ?? null,
            'description' => $validated['description'] ?? null,
            'duration' => $validated['duration'] ?? null,
            'location' => $validated['location'] ?? null,
            'province' => $validated['province'] ?? null,
            'start_location' => $validated['start_location'] ?? $validated['startLocation'] ?? null,

            'experience_address' => $validated['experience_address'] ?? null,
            'experience_latitude' => $validated['experience_latitude'] ?? null,
            'experience_longitude' => $validated['experience_longitude'] ?? null,

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
        $provider = $this->currentProvider($request);

        if ((int) $experience->provider_id !== (int) $provider->id) {
            abort(403, 'No tienes permiso para modificar esta experiencia.');
        }
    }

    private function currentProvider(Request $request): Provider
    {
        $user = $request->user();

        $provider = Provider::where('user_id', $user->id)->first();

        if (! $provider) {
            abort(response()->json([
                'message' => 'Este usuario no tiene un perfil de proveedor asociado.',
            ], 403));
        }

        return $provider;
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

        $firstPhoto = $experience->relationLoaded('photos')
            ? $experience->photos->sortBy('sort_order')->first()
            : $experience->photos()->orderBy('sort_order')->first();

        $displayPhoto = $coverPhoto ?? $firstPhoto;

        $mapPickupPoints = $experience->relationLoaded('mapPickupPoints')
            ? $experience->mapPickupPoints
            : $experience->mapPickupPoints()->get();

        return [
            'id' => $experience->id,
            'title' => $experience->title,
            'category' => $experience->category,
            'description' => $experience->description,
            'duration' => $experience->duration,
            'location' => $experience->location,
            'province' => $experience->province,
            'start_location' => $experience->start_location,

            'experience_address' => $experience->experience_address,
            'experience_latitude' => $experience->experience_latitude !== null
                ? (float) $experience->experience_latitude
                : null,
            'experience_longitude' => $experience->experience_longitude !== null
                ? (float) $experience->experience_longitude
                : null,

            'pickup_points' => $experience->pickup_points ?? [],
            'map_pickup_points' => $mapPickupPoints->map(fn ($point) => [
                'id' => $point->id,
                'name' => $point->name,
                'address' => $point->address,
                'latitude' => (float) $point->latitude,
                'longitude' => (float) $point->longitude,
                'instructions' => $point->instructions,
                'sort_order' => (int) $point->sort_order,
            ])->values(),

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

            'cover_photo_url' => $displayPhoto
                ? asset('storage/' . ltrim($displayPhoto->path, '/'))
                : null,

            'photos' => $experience->relationLoaded('photos')
                ? $experience->photos->map(fn ($photo) => [
                    'id' => $photo->id,
                    'url' => asset('storage/' . ltrim($photo->path, '/')),
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

    private function syncMapPickupPoints(ProviderExperience $experience, array $points): void
    {
        $experience->mapPickupPoints()->delete();

        foreach ($points as $index => $point) {
            $latitude = $point['latitude'] ?? null;
            $longitude = $point['longitude'] ?? null;

            if ($latitude === null || $longitude === null) {
                continue;
            }

            $experience->mapPickupPoints()->create([
                'name' => $point['name'] ?? null,
                'address' => $point['address'] ?? null,
                'latitude' => $latitude,
                'longitude' => $longitude,
                'instructions' => $point['instructions'] ?? null,
                'sort_order' => $index,
                'is_active' => true,
            ]);
        }
    }
}