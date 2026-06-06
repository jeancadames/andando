<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\CustomerFavoriteExperience;
use App\Models\ProviderBooking;
use App\Models\ProviderReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

/**
 * Controlador del perfil del cliente.
 *
 * Maneja:
 * - Consulta del perfil.
 * - Estadísticas del cliente.
 * - Próxima reserva.
 * - Actualización de datos personales.
 * - Actualización de foto.
 * - Cierre de sesión.
 */
class ClientProfileController extends Controller
{
    /**
     * Devuelve el perfil completo del cliente autenticado.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        $toursCount = ProviderBooking::query()
            ->where('user_id', $user->id)
            ->whereIn('status', ['confirmed', 'completed'])
            ->count();

        $pendingBookingsCount = ProviderBooking::query()
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->count();

        $favoritesCount = CustomerFavoriteExperience::query()
            ->where('user_id', $user->id)
            ->count();

        $reviewsCount = ProviderReview::query()
            ->where('user_id', $user->id)
            ->count();

        /**
         * IMPORTANTE:
         * Tu tabla provider_bookings no tiene starts_at.
         * La fecha real de la reserva es booking_date.
         */
        $nextBooking = ProviderBooking::query()
            ->with(['experience'])
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->whereDate('booking_date', '>=', now()->toDateString())
            ->orderBy('booking_date')
            ->first();

        return response()->json([
            'message' => 'Perfil obtenido correctamente.',
            'data' => [
                'user' => $this->formatUser($user),
                'stats' => [
                    'tours_count' => $toursCount,
                    'reviews_count' => $reviewsCount,
                    'favorites_count' => $favoritesCount,
                    'pending_bookings_count' => $pendingBookingsCount,
                ],
                'next_booking' => $nextBooking
                    ? $this->formatNextBooking($nextBooking)
                    : null,
            ],
        ]);
    }

    /**
     * Actualiza los datos personales del cliente.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'birth_date' => ['nullable', 'date', 'before:today'],
            'gender' => [
                'nullable',
                'string',
                Rule::in(['male', 'female', 'other', 'prefer_not_to_say']),
            ],
            'nationality' => ['nullable', 'string', 'max:100'],
            'residence_city' => ['nullable', 'string', 'max:100'],
            'preferred_currency' => ['nullable', 'string', Rule::in(['DOP', 'USD', 'EUR'])],
            'language' => ['nullable', 'string', Rule::in(['es', 'en'])],
            'country' => ['nullable', 'string', 'max:100'],
        ]);

        $user->update([
            'name' => $validated['name'],
            'phone' => $validated['phone'] ?? null,
            'birth_date' => $validated['birth_date'] ?? null,
            'gender' => $validated['gender'] ?? null,
            'nationality' => $validated['nationality'] ?? null,
            'residence_city' => $validated['residence_city'] ?? null,
            'preferred_currency' => $validated['preferred_currency'] ?? 'DOP',
            'language' => $validated['language'] ?? 'es',
            'country' => $validated['country'] ?? null,
        ]);

        return response()->json([
            'message' => 'Perfil actualizado correctamente.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
            ],
        ]);
    }

    /**
     * Actualiza la foto de perfil del cliente.
     */
    public function updatePhoto(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ]);

        if ($user->avatar_path && Storage::disk('public')->exists($user->avatar_path)) {
            Storage::disk('public')->delete($user->avatar_path);
        }

        $path = $validated['avatar']->store(
            'customer-profiles/user_' . $user->id,
            'public'
        );

        $user->update([
            'avatar_path' => $path,
        ]);

        return response()->json([
            'message' => 'Foto de perfil actualizada correctamente.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
            ],
        ]);
    }

    /**
     * Cierra la sesión actual del cliente.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Sesión cerrada correctamente.',
        ]);
    }

    /**
     * Formatea el usuario para Flutter.
     */
    private function formatUser($user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'type' => $user->type,
            'avatar_path' => $user->avatar_path,
            'avatar_url' => $user->avatar_path
                ? url('/api/public-files/' . $user->avatar_path)
                : null,
            'birth_date' => $user->birth_date
                ? $user->birth_date->format('Y-m-d')
                : null,
            'gender' => $user->gender,
            'nationality' => $user->nationality,
            'residence_city' => $user->residence_city,
            'preferred_currency' => $user->preferred_currency,
            'language' => $user->language,
            'country' => $user->country,
            'created_at' => $user->created_at?->toISOString(),
        ];
    }

    /**
     * Formatea la próxima reserva para Flutter.
     */
    private function formatNextBooking(ProviderBooking $booking): array
    {
        return [
            'id' => $booking->id,
            'booking_code' => $booking->booking_code,
            'status' => $booking->status,
            'experience_title' => $booking->experience?->title,
            'experience_location' => $booking->experience?->location,
            'experience_province' => $booking->experience?->province,
            'booking_date' => $booking->booking_date
                ? $booking->booking_date->format('Y-m-d')
                : null,
            'starts_at' => null,
            'guests_count' => $booking->guests_count,
            'total_amount' => (float) $booking->total_amount,
            'currency' => 'DOP',
        ];
    }
}