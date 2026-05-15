<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Api\Client\ExploreController;
use App\Http\Controllers\Controller;
use App\Models\ProviderExperience;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controlador público para explorar experiencias.
 *
 * Este controlador alimenta la pantalla "Explorar" del cliente.
 * Puede ser consumido por:
 * - usuarios customer autenticados
 * - visitantes sin iniciar sesión
 */
class ExploreController extends Controller
{
    /**
     * Lista experiencias publicadas y activas.
     *
     * Filtros soportados:
     * - search: busca por título, descripción, provincia o ubicación.
     * - category: filtra por categoría.
     * - province: filtra por provincia.
     */
    public function index(Request $request): JsonResponse
    {
        $query = ProviderExperience::query()
            ->with(['coverPhoto', 'provider'])
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

    /**
     * Muestra el detalle público de una experiencia.
     */
    public function show(int $id): JsonResponse
    {
        $experience = ProviderExperience::query()
            ->with(['photos', 'coverPhoto', 'provider'])
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

    /**
     * Devuelve las categorías disponibles.
     */
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

    /**
     * Formatea una experiencia para el frontend mobile.
     */
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
                ? asset('storage/' . ltrim($coverPhoto->path, '/'))
                : null,
            'rating' => $experience->rating
                ? round((float) $experience->rating, 1)
                : 0,
            'reviews_count' => (int) ($experience->reviews_count ?? 0),
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
}