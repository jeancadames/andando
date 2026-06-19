<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\CustomerFavoriteExperience;
use App\Models\ProviderExperience;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExploreController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = ProviderExperience::query()
            ->with([
                'coverPhoto',
                'photos',
                'provider',
                'mapPickupPoints',
                'schedules' => function ($scheduleQuery) {
                    $this->availableScheduleQuery($scheduleQuery);
                    $scheduleQuery->orderBy('starts_at');
                },
            ])
            ->withAvg([
                'reviews as rating' => function ($query) {
                    $query->where('is_visible', true);
                },
            ], 'rating')
            ->withCount([
                'reviews as reviews_count' => function ($query) {
                    $query->where('is_visible', true);
                },
            ])
            ->where('status', 'published')
            ->where('is_active', true)
            ->whereNotNull('published_at')
            ->whereHas('schedules', function ($scheduleQuery) {
                $this->availableScheduleQuery($scheduleQuery);
            });

        if ($request->filled('search')) {
            $search = trim($request->query('search'));

            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('province', 'like', "%{$search}%")
                    ->orWhere('location', 'like', "%{$search}%");
            });
        }

        if ($request->filled('category') && $request->query('category') !== 'Todos') {
            $query->where('category', $request->query('category'));
        }

        /**
         * Filtro por fecha seleccionada.
         *
         * Devuelve solo experiencias que tengan al menos un horario activo,
         * futuro/vigente, dentro del día seleccionado.
         *
         * Query param esperado:
         * date=YYYY-MM-DD
         */
        if ($request->filled('date')) {
            $date = $request->date('date');

            $query->whereHas('schedules', function ($scheduleQuery) use ($date) {
                $this->availableScheduleQuery($scheduleQuery);
                $scheduleQuery->whereDate('starts_at', $date);
            });
        }

        if ($request->filled('province')) {
            $query->where('province', $request->query('province'));
        }

        $userLatitude = $request->query('latitude') ?? $request->query('lat');
        $userLongitude = $request->query('longitude') ?? $request->query('lng');

        $hasUserLocation = is_numeric($userLatitude) && is_numeric($userLongitude);

        if ($hasUserLocation) {
            $lat = (float) $userLatitude;
            $lng = (float) $userLongitude;

            $radiusKm = $request->query('radius_km');

            $radiusKm = is_numeric($radiusKm)
                ? max(10, min(200, (float) $radiusKm))
                : null;

            $query
                ->whereNotNull('experience_latitude')
                ->whereNotNull('experience_longitude')
                ->select('provider_experiences.*')
                ->selectRaw(
                    '(6371 * acos(
                        cos(radians(?)) *
                        cos(radians(experience_latitude)) *
                        cos(radians(experience_longitude) - radians(?)) +
                        sin(radians(?)) *
                        sin(radians(experience_latitude))
                    )) as distance_km',
                    [$lat, $lng, $lat]
                );

            if ($radiusKm !== null) {
                $query->having('distance_km', '<=', $radiusKm);
            }

            $query->orderBy('distance_km');
        } else {
            $query->latest('published_at');
        }

        $experiences = $query
            ->paginate(12)
            ->through(fn (ProviderExperience $experience) => $this->formatExperience($experience));

        return response()->json([
            'message' => 'Experiencias obtenidas correctamente.',
            'data' => $experiences,
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $experience = ProviderExperience::query()
            ->with([
                'photos',
                'coverPhoto',
                'provider',
                'mapPickupPoints',
                'schedules' => function ($scheduleQuery) {
                    $this->availableScheduleQuery($scheduleQuery);
                    $scheduleQuery->orderBy('starts_at');
                },
            ])
            ->withAvg([
                'reviews as rating' => function ($query) {
                    $query->where('is_visible', true);
                },
            ], 'rating')
            ->withCount([
                'reviews as reviews_count' => function ($query) {
                    $query->where('is_visible', true);
                },
            ])
            ->where('status', 'published')
            ->where('is_active', true)
            ->whereNotNull('published_at')
            ->whereHas('schedules', function ($scheduleQuery) {
                $this->availableScheduleQuery($scheduleQuery);
            })
            ->findOrFail($id);

        return response()->json([
            'message' => 'Experiencia obtenida correctamente.',
            'data' => $this->formatExperience($experience, includeDetails: true),
        ]);
    }

    public function categories(): JsonResponse
    {
        $categories = ProviderExperience::query()
            ->where('status', 'published')
            ->where('is_active', true)
            ->whereNotNull('published_at')
            ->whereNotNull('category')
            ->whereHas('schedules', function ($scheduleQuery) {
                $this->availableScheduleQuery($scheduleQuery);
            })
            ->distinct()
            ->orderBy('category')
            ->pluck('category')
            ->prepend('Todos')
            ->values();

        return response()->json([
            'message' => 'Categorías obtenidas correctamente.',
            'data' => $categories,
        ]);
    }

    private function formatExperience(
        ProviderExperience $experience,
        bool $includeDetails = false
    ): array {
        $coverPhoto = $experience->coverPhoto;

        $firstPhoto = $experience->relationLoaded('photos')
            ? $experience->photos->sortBy('sort_order')->first()
            : $experience->photos()->orderBy('sort_order')->first();

        $displayPhoto = $coverPhoto ?? $firstPhoto;

        $mapPickupPoints = $experience->relationLoaded('mapPickupPoints')
            ? $experience->mapPickupPoints
            : $experience->mapPickupPoints()->get();

        $data = [
            'id' => $experience->id,
            'title' => $experience->title,
            'category' => $experience->category,
            'description' => $experience->description,
            'duration' => $experience->duration,
            'location' => $experience->location,
            'province' => $experience->province,
            'experience_address' => $experience->experience_address,
            'experience_latitude' => $experience->experience_latitude !== null
                ? (float) $experience->experience_latitude
                : null,
            'experience_longitude' => $experience->experience_longitude !== null
                ? (float) $experience->experience_longitude
                : null,
            'includes_transport' => (bool) $experience->includes_transport,
            'distance_km' => isset($experience->distance_km)
                ? round((float) $experience->distance_km, 1)
                : null,
            'price' => (float) $experience->price,
            'currency' => $experience->currency ?? 'DOP',
            'capacity' => $experience->capacity,
            'cancellation_policy' => $experience->cancellation_policy,
            'instant_confirmation' => true,

            'cover_photo_url' => $displayPhoto
                ? $this->formatPhotoUrl($displayPhoto->path)
                : null,

            'rating' => $experience->rating
                ? round((float) $experience->rating, 1)
                : 0,
            'reviews_count' => (int) ($experience->reviews_count ?? 0),
            'is_favorite' => $this->isFavoriteForCurrentUser($experience),
            'available_dates' => $this->formatAvailableDates($experience),
            'available_schedules' => $this->formatAvailableSchedules($experience),
            'map_pickup_points' => $mapPickupPoints->map(fn ($point) => [
                'id' => $point->id,
                'name' => $point->name,
                'address' => $point->address,
                'latitude' => (float) $point->latitude,
                'longitude' => (float) $point->longitude,
                'instructions' => $point->instructions,
                'sort_order' => (int) $point->sort_order,
            ])->values(),
            'next_available_date' => $experience->schedules()
                ->where('status', 'active')
                ->where('starts_at', '>=', now())
                ->orderBy('starts_at')
                ->first()?->starts_at?->toDateString(),

            'next_available_datetime' => $experience->schedules()
                ->where('status', 'active')
                ->where('starts_at', '>=', now())
                ->orderBy('starts_at')
                ->first()?->starts_at?->toIso8601String(),
            'provider' => [
                'id' => $experience->provider?->id,
                'business_name' => $experience->provider?->business_name,
            ],
        ];

        if ($includeDetails) {
            $data['start_location'] = $experience->start_location;
            $data['pickup_points'] = $experience->pickup_points ?? [];
            $data['itinerary'] = $experience->itinerary ?? [];
            $data['amenities'] = $experience->amenities ?? [];
            $data['included'] = $experience->included ?? [];
            $data['not_included'] = $experience->not_included ?? [];
            $data['requirements'] = $experience->requirements ?? [];

            $data['photos'] = $experience->photos
                ->sortBy('sort_order')
                ->map(fn ($photo) => [
                    'id' => $photo->id,
                    'url' => $this->formatPhotoUrl($photo->path),
                    'is_cover' => $photo->is_cover,
                    'sort_order' => $photo->sort_order,
                ])
                ->values();
        }

        return $data;
    }

    private function formatAvailableDates(
        ProviderExperience $experience
    ) {
        return $experience->schedules()
            ->where('status', 'active')
            ->where('starts_at', '>=', now())
            ->orderBy('starts_at')
            ->pluck('starts_at')
            ->map(fn ($date) => $date?->toIso8601String())
            ->values();
    }

    private function formatAvailableSchedules(
        ProviderExperience $experience
    ) {
        return $experience->schedules()
            ->where('status', 'active')
            ->where('starts_at', '>=', now())
            ->orderBy('starts_at')
            ->get()
            ->map(function ($schedule) use ($experience) {

                $reservedGuests = $schedule->bookings()
                    ->whereIn('status', [
                        'pending',
                        'confirmed',
                    ])
                    ->sum('guests_count');

                $availableSpots = max(
                    0,
                    $schedule->capacity - $reservedGuests,
                );

                return [
                    'id' => $schedule->id,
                    'starts_at' => $schedule->starts_at?->toIso8601String(),
                    'capacity' => $schedule->capacity,
                    'available_spots' => $availableSpots,
                    'price' => (float) (
                        $schedule->price ?? $experience->price
                    ),
                    'currency' => $schedule->currency
                        ?? $experience->currency
                        ?? 'DOP',
                ];
            })
            ->filter(
                fn ($schedule) =>
                    $schedule['available_spots'] > 0
            )
            ->values();
    }

    private function availableScheduleQuery($scheduleQuery): void
    {
        $scheduleQuery
            ->where('status', 'active')
            ->where('starts_at', '>=', now());
    }

    private function isFavoriteForCurrentUser(ProviderExperience $experience): bool
    {
        $user = auth('sanctum')->user();

        if (!$user) {
            return false;
        }

        return CustomerFavoriteExperience::query()
            ->where('user_id', $user->id)
            ->where('provider_experience_id', $experience->id)
            ->exists();
    }

    private function formatPhotoUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        return url('/api/public-files/' . ltrim($path, '/'));
    }
}
