<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientReviewController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'booking_id' => ['required', 'integer', 'exists:provider_bookings,id'],
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:500'],
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

        return response()->json([
            'message' => 'Reseña publicada correctamente.',
            'data' => [
                'id' => $review->id,
                'booking_id' => $review->provider_booking_id,
                'experience_id' => $review->provider_experience_id,
                'rating' => $review->rating,
                'comment' => $review->comment,
            ],
        ], 201);
    }

    public function experienceReviews(Request $request, ProviderExperience $experience): JsonResponse
    {
        $reviews = ProviderReview::query()
            ->with(['user', 'booking'])
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
                'reviews' => $reviews->map(function (ProviderReview $review) use ($request, $experience) {
                    $isOwner = $request->user()
                        ? (int) $review->user_id === (int) $request->user()->id
                        : false;

                    return [
                        'id' => $review->id,
                        'rating' => $review->rating,
                        'comment' => $review->comment,
                        'customer_name' => $review->user?->name ?? 'Viajero',
                        'created_at' => $review->created_at?->toIso8601String(),
                        'booking_id' => $review->provider_booking_id,
                        'is_owner' => $isOwner,
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
                        ] : null,
                    ];
                })->values(),
            ],
        ]);
    }

    public function update(Request $request, ProviderReview $review): JsonResponse
    {
        $data = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:500'],
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

        return response()->json([
            'message' => 'Reseña actualizada correctamente.',
            'data' => [
                'id' => $review->id,
                'booking_id' => $review->provider_booking_id,
                'experience_id' => $review->provider_experience_id,
                'rating' => $review->rating,
                'comment' => $review->comment,
            ],
        ]);
    }

    public function destroy(Request $request, ProviderReview $review): JsonResponse
    {
        if ((int) $review->user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'No tienes permiso para eliminar esta reseña.',
            ], 403);
        }

        $review->delete();

        return response()->json([
            'message' => 'Reseña eliminada correctamente.',
        ]);
    }

}