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
            ->with(['coverPhoto', 'provider', 'schedules'])
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
            ->latest('published_at');

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

        if ($request->filled('province')) {
            $query->where('province', $request->query('province'));
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
            ->with(['photos', 'coverPhoto', 'provider', 'schedules'])
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

        $data = [
            'id' => $experience->id,
            'title' => $experience->title,
            'category' => $experience->category,
            'description' => $experience->description,
            'duration' => $experience->duration,
            'location' => $experience->location,
            'province' => $experience->province,
            'price' => (float) $experience->price,
            'currency' => $experience->currency ?? 'DOP',
            'capacity' => $experience->capacity,
            'cancellation_policy' => $experience->cancellation_policy,
            'instant_confirmation' => true,
            'cover_photo_url' => $coverPhoto
                ? $this->formatPhotoUrl($coverPhoto->path)
                : null,
            'rating' => $experience->rating
                ? round((float) $experience->rating, 1)
                : 0,
            'reviews_count' => (int) ($experience->reviews_count ?? 0),
            'is_favorite' => $this->isFavoriteForCurrentUser($experience),
            'available_dates' => $this->formatAvailableDates($experience),
            'available_schedules' => $this->formatAvailableSchedules($experience),
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

            $data['photos'] = $experience->photos->map(fn ($photo) => [
                'id' => $photo->id,
                'url' => asset('storage/' . ltrim($photo->path, '/')),
                'is_cover' => $photo->is_cover,
                'sort_order' => $photo->sort_order,
            ])->values();
        }

        return $data;
    }

    private function formatAvailableDates(ProviderExperience $experience)
    {
        return $experience->schedules
            ->where('status', 'active')
            ->where('starts_at', '>=', now())
            ->sortBy('starts_at')
            ->map(fn ($schedule) => $schedule->starts_at?->toIso8601String())
            ->filter()
            ->values();
    }

    private function formatAvailableSchedules(ProviderExperience $experience)
    {
        return $experience->schedules
            ->where('status', 'active')
            ->where('starts_at', '>=', now())
            ->sortBy('starts_at')
            ->map(function ($schedule) use ($experience) {
                $reservedGuests = $schedule->bookings()
                    ->whereIn('status', ['pending', 'confirmed'])
                    ->sum('guests_count');

                $availableSpots = max(0, $schedule->capacity - $reservedGuests);

                return [
                    'id' => $schedule->id,
                    'starts_at' => $schedule->starts_at?->toIso8601String(),
                    'capacity' => $schedule->capacity,
                    'available_spots' => $availableSpots,
                    'price' => (float) ($schedule->price ?? $experience->price),
                    'currency' => $schedule->currency ?? $experience->currency ?? 'DOP',
                ];
            })
            ->filter(fn ($schedule) => $schedule['available_spots'] > 0)
            ->values();
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
        if (!$path) {
            return null;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        return asset('storage/' . ltrim($path, '/'));
    }
}