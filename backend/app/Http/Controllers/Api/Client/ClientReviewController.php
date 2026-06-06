<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderReview;
use App\Models\ProviderReviewPhoto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ClientReviewController extends Controller
{
    /**
     * Crea una reseña para una reserva completada.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'booking_id' => ['required', 'integer', 'exists:provider_bookings,id'],
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:500'],
            'photos' => ['nullable', 'array', 'max:6'],
            'photos.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ]);

        $user = $request->user();

        $booking = ProviderBooking::query()
            ->with(['experience', 'review'])
            ->where('id', $data['booking_id'])
            ->where('user_id', $user->id)
            ->firstOrFail();

        if ($booking->status !== 'completed') {
            return response()->json([
                'message' => 'Solo puedes calificar reservas completadas.',
            ], 422);
        }

        if ($booking->review) {
            return response()->json([
                'message' => 'Esta reserva ya tiene una reseña.',
            ], 422);
        }

        if (! $booking->provider_experience_id) {
            return response()->json([
                'message' => 'Esta reserva no tiene una experiencia asociada.',
            ], 422);
        }

        $review = ProviderReview::create([
            'provider_id' => $booking->provider_id,
            'provider_experience_id' => $booking->provider_experience_id,
            'provider_booking_id' => $booking->id,
            'user_id' => $user->id,
            'rating' => $data['rating'],
            'comment' => $data['comment'] ?? null,
            'is_visible' => true,
        ]);

        $this->storeReviewPhotos($request, $review);

        $review->load(['photos', 'user']);
        $review->loadCount([
            'comments as comments_count' => fn ($query) => $query->where('is_visible', true),
        ]);

        return response()->json([
            'message' => 'Reseña publicada correctamente.',
            'data' => $this->reviewPayload($review),
        ], 201);
    }

    /**
     * Devuelve las reseñas visibles de una experiencia.
     */
    public function experienceReviews(
        Request $request,
        ProviderExperience $experience
    ): JsonResponse {
        $reviews = ProviderReview::query()
            ->with(['user', 'booking', 'photos'])
            ->withCount([
                'comments as comments_count' => fn ($query) => $query->where('is_visible', true),
            ])
            ->where('provider_experience_id', $experience->id)
            ->where('is_visible', true)
            ->latest()
            ->get();

        $averageRating = round((float) $reviews->avg('rating'), 1);
        $totalReviews = $reviews->count();

        return response()->json([
            'message' => 'Reseñas obtenidas correctamente.',
            'data' => [
                'average_rating' => $averageRating,
                'total_reviews' => $totalReviews,
                'distribution' => [
                    5 => $reviews->where('rating', 5)->count(),
                    4 => $reviews->where('rating', 4)->count(),
                    3 => $reviews->where('rating', 3)->count(),
                    2 => $reviews->where('rating', 2)->count(),
                    1 => $reviews->where('rating', 1)->count(),
                ],
                'reviews' => $reviews
                    ->map(fn (ProviderReview $review) => $this->experienceReviewPayload(
                        $review,
                        $request,
                        $experience,
                    ))
                    ->values(),
            ],
        ]);
    }

    /**
     * Actualiza una reseña propia.
     */
    public function update(Request $request, ProviderReview $review): JsonResponse
    {
        $data = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:500'],
            'photos' => ['nullable', 'array', 'max:6'],
            'photos.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'remove_existing_photos' => ['nullable', 'boolean'],
        ]);

        if ((int) $review->user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'No tienes permiso para editar esta reseña.',
            ], 403);
        }

        $review->update([
            'rating' => $data['rating'],
            'comment' => $data['comment'] ?? null,
        ]);

        if ($request->boolean('remove_existing_photos')) {
            $this->deleteReviewPhotos($review);
        }

        $this->storeReviewPhotos($request, $review);

        $review->load(['photos', 'user']);
        $review->loadCount([
            'comments as comments_count' => fn ($query) => $query->where('is_visible', true),
        ]);

        return response()->json([
            'message' => 'Reseña actualizada correctamente.',
            'data' => $this->reviewPayload($review),
        ]);
    }

    /**
     * Elimina una reseña propia junto con sus fotos.
     */
    public function destroy(Request $request, ProviderReview $review): JsonResponse
    {
        if ((int) $review->user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'No tienes permiso para eliminar esta reseña.',
            ], 403);
        }

        $this->deleteReviewPhotos($review);
        $review->delete();

        return response()->json([
            'message' => 'Reseña eliminada correctamente.',
        ]);
    }

    /**
     * Elimina una foto individual de una reseña propia.
     */
    public function destroyPhoto(
        Request $request,
        ProviderReview $review,
        ProviderReviewPhoto $photo
    ): JsonResponse {
        if ((int) $review->user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'No tienes permiso para eliminar esta foto.',
            ], 403);
        }

        if ((int) $photo->provider_review_id !== (int) $review->id) {
            return response()->json([
                'message' => 'Esta foto no pertenece a la reseña indicada.',
            ], 422);
        }

        Storage::disk('public')->delete($photo->photo_path);
        $photo->delete();

        return response()->json([
            'message' => 'Foto eliminada correctamente.',
        ]);
    }

    /**
     * Guarda nuevas fotos de una reseña sin superar 6.
     */
    private function storeReviewPhotos(Request $request, ProviderReview $review): void
    {
        if (! $request->hasFile('photos')) {
            return;
        }

        $currentCount = $review->photos()->count();

        foreach ($request->file('photos') as $index => $photo) {
            if ($currentCount + $index >= 6) {
                break;
            }

            $path = $photo->store(
                'review-photos/review_' . $review->id,
                'public'
            );

            $review->photos()->create([
                'photo_path' => $path,
                'sort_order' => $currentCount + $index,
            ]);
        }
    }

    /**
     * Elimina todas las fotos físicas y registros de una reseña.
     */
    private function deleteReviewPhotos(ProviderReview $review): void
    {
        $review->loadMissing('photos');

        foreach ($review->photos as $photo) {
            Storage::disk('public')->delete($photo->photo_path);
            $photo->delete();
        }
    }

    /**
     * Payload base para crear/editar reseñas.
     */
    private function reviewPayload(ProviderReview $review): array
    {
        return [
            'id' => $review->id,
            'booking_id' => $review->provider_booking_id,
            'experience_id' => $review->provider_experience_id,
            'rating' => $review->rating,
            'comment' => $review->comment,
            'comments_count' => (int) ($review->comments_count ?? 0),
            'customer_name' => $review->user?->name ?? 'Viajero',
            'customer_photo_url' => $this->userPhotoUrl($review->user),
            'created_at' => $review->created_at?->toIso8601String(),
            'updated_at' => $review->updated_at?->toIso8601String(),
            'is_edited' => $this->isEdited($review->created_at, $review->updated_at),
            'photos' => $this->photosPayload($review),
        ];
    }

    /**
     * Payload de reseña usado en el detalle de experiencia.
     */
    private function experienceReviewPayload(
        ProviderReview $review,
        Request $request,
        ProviderExperience $experience
    ): array {
        $isOwner = $request->user()
            ? (int) $review->user_id === (int) $request->user()->id
            : false;

        return [
            'id' => $review->id,
            'rating' => $review->rating,
            'comment' => $review->comment,
            'comments_count' => (int) ($review->comments_count ?? 0),
            'customer_name' => $review->user?->name ?? 'Viajero',
            'customer_photo_url' => $this->userPhotoUrl($review->user),
            'created_at' => $review->created_at?->toIso8601String(),
            'updated_at' => $review->updated_at?->toIso8601String(),
            'is_edited' => $this->isEdited($review->created_at, $review->updated_at),
            'booking_id' => $review->provider_booking_id,
            'is_owner' => $isOwner,
            'photos' => $this->photosPayload($review),
            'booking' => $isOwner && $review->booking ? [
                'id' => $review->booking->id,
                'experience_id' => $review->provider_experience_id,
                'booking_code' => $review->booking->booking_code,
                'status' => $review->booking->status,
                'experience_title' => $experience->title,
                'location' => $experience->location,
                'province' => $experience->province,
                'cover_photo_url' => $experience->coverPhoto?->url,
                'booking_date' => $review->booking->booking_date,
                'starts_at' => $review->booking->starts_at,
                'guests_count' => $review->booking->guests_count,
                'unit_price' => $review->booking->unit_price,
                'total_amount' => $review->booking->total_amount,
                'currency' => $review->booking->currency,
                'pickup_point' => $review->booking->pickup_point,
                'duration' => $experience->duration,
                'has_review' => true,
                'review_id' => $review->id,
                'review_rating' => $review->rating,
                'review_comment' => $review->comment,
                'review_photos' => $this->photosPayload($review),
            ] : null,
        ];
    }

    /**
     * Formatea las fotos de una reseña para Flutter.
     */
    private function photosPayload(ProviderReview $review): array
    {
        $review->loadMissing('photos');

        return $review->photos
            ->map(fn ($photo) => [
                'id' => $photo->id,
                'url' => $photo->photo_url,
            ])
            ->values()
            ->toArray();
    }

    /**
     * Resuelve la foto pública del usuario.
     */
    private function userPhotoUrl($user): ?string
    {
        if (! $user) {
            return null;
        }

        $path = $user->photo_path
            ?? $user->avatar_path
            ?? $user->profile_photo_path
            ?? null;

        if (! $path) {
            return null;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        return url('/api/public-files/' . ltrim($path, '/'));
    }

    /**
     * Indica si el registro fue editado después de su creación.
     */
    private function isEdited($createdAt, $updatedAt): bool
    {
        if (! $createdAt || ! $updatedAt) {
            return false;
        }

        return $updatedAt->gt($createdAt->copy()->addSeconds(2));
    }
}