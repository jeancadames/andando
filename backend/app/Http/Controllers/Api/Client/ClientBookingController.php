<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ClientBookingController extends Controller
{
    /**
     * Lista las reservas del cliente autenticado.
     *
     * Este endpoint alimenta la pantalla "Mis Reservas" en Flutter.
     *
     * Carga:
     * - experiencia relacionada
     * - foto de portada
     * - galería de fotos como fallback
     * - schedule reservado
     *
     * Importante:
     * Si la experiencia no tiene una foto marcada como portada,
     * se usa la primera foto disponible.
     */
    public function index(Request $request): JsonResponse
    {
        $bookings = ProviderBooking::query()
            ->with([
                'experience.coverPhoto',
                'experience.photos',
                'schedule',
            ])
            ->where('user_id', $request->user()->id)
            ->latest('booking_date')
            ->get()
            ->map(function (ProviderBooking $booking) {
                $experience = $booking->experience;
                $schedule = $booking->schedule;

                return [
                    'id' => $booking->id,
                    'booking_code' => $booking->booking_code,
                    'status' => $booking->status,
                    'experience_title' => $experience?->title ?? 'Experiencia',
                    'location' => $experience?->location,
                    'province' => $experience?->province,

                    /**
                     * Foto principal de la experiencia reservada.
                     *
                     * Usa:
                     * 1. coverPhoto si existe.
                     * 2. primera foto por sort_order si no hay portada.
                     */
                    'cover_photo_url' => $this->resolveExperienceCoverPhotoUrl(
                        $experience,
                    ),

                    'booking_date' => $booking->booking_date?->toIso8601String(),
                    'starts_at' => $schedule?->starts_at?->toIso8601String()
                        ?? $booking->booking_date?->toIso8601String(),
                    'guests_count' => (int) $booking->guests_count,
                    'unit_price' => (float) $booking->unit_price,
                    'total_amount' => (float) $booking->total_amount,
                    'currency' => $experience?->currency ?? 'DOP',
                    'pickup_point' => $experience?->start_location
                        ?? $experience?->location
                        ?? $experience?->province,
                    'duration' => $experience?->duration,
                ];
            })
            ->values();

        return response()->json([
            'message' => 'Reservas obtenidas correctamente.',
            'data' => $bookings,
        ]);
    }

    /**
     * Crea una reserva para el cliente autenticado.
     *
     * Valida:
     * - que exista el schedule
     * - que el schedule esté activo
     * - que existan cupos suficientes
     *
     * Luego calcula:
     * - precio unitario
     * - total
     * - ganancia del proveedor
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'provider_experience_schedule_id' => [
                'required',
                'integer',
                'exists:provider_experience_schedules,id',
            ],
            'guests_count' => [
                'required',
                'integer',
                'min:1',
            ],
        ]);

        $user = $request->user();

        $booking = DB::transaction(function () use ($data, $user) {
            $schedule = ProviderExperienceSchedule::query()
                ->with('experience.provider')
                ->where('id', $data['provider_experience_schedule_id'])
                ->where('status', 'active')
                ->lockForUpdate()
                ->firstOrFail();

            /**
             * Calculamos los cupos ya reservados para este schedule.
             *
             * Solo contamos reservas pending/confirmed porque son las que
             * todavía ocupan cupos.
             */
            $reservedGuests = ProviderBooking::query()
                ->where('provider_experience_schedule_id', $schedule->id)
                ->whereIn('status', ['pending', 'confirmed'])
                ->sum('guests_count');

            $availableSpots = $schedule->capacity - $reservedGuests;

            if ($data['guests_count'] > $availableSpots) {
                abort(422, 'No hay cupos suficientes para esta fecha.');
            }

            $unitPrice = $schedule->price ?? $schedule->experience->price;
            $totalAmount = $unitPrice * $data['guests_count'];

            return ProviderBooking::create([
                'provider_id' => $schedule->provider_id,
                'provider_experience_id' => $schedule->provider_experience_id,
                'provider_experience_schedule_id' => $schedule->id,
                'user_id' => $user->id,
                'booking_code' => 'ANDO-' . strtoupper(Str::random(8)),
                'customer_name' => $user->name,
                'customer_phone' => $user->phone ?? null,
                'customer_email' => $user->email,
                'booking_date' => $schedule->starts_at,
                'guests_count' => $data['guests_count'],
                'unit_price' => $unitPrice,
                'total_amount' => $totalAmount,
                'provider_earning' => $totalAmount,
                'status' => 'pending',
            ]);
        });

        return response()->json([
            'message' => 'Reserva creada correctamente.',
            'data' => [
                'id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'status' => $booking->status,
                'total_amount' => (float) $booking->total_amount,
            ],
        ], 201);
    }

    /**
     * Resuelve la imagen principal de una experiencia.
     *
     * Prioridad:
     * 1. Foto marcada como portada.
     * 2. Primera foto disponible ordenada por sort_order.
     * 3. null si no hay fotos.
     */
    private function resolveExperienceCoverPhotoUrl(
        ?ProviderExperience $experience,
    ): ?string {
        if (! $experience) {
            return null;
        }

        $coverPhoto = $experience->coverPhoto;

        $firstPhoto = $experience->relationLoaded('photos')
            ? $experience->photos->sortBy('sort_order')->first()
            : $experience->photos()->orderBy('sort_order')->first();

        $photo = $coverPhoto ?? $firstPhoto;

        if (! $photo) {
            return null;
        }

        return $this->formatPhotoUrl($photo->path);
    }

    /**
     * Genera una URL pública compatible con Flutter Web.
     *
     * Antes usábamos:
     * /storage/...
     *
     * Pero en desarrollo con:
     * php artisan serve
     *
     * .htaccess no se aplica, así que los headers CORS no llegan a Flutter Web.
     *
     * Por eso ahora usamos:
     * /api/storage/...
     *
     * Esa ruta sí pasa por Laravel y devuelve la imagen con headers CORS.
     */
    private function formatPhotoUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        if (
            str_starts_with($path, 'http://') ||
            str_starts_with($path, 'https://')
        ) {
            return $path;
        }

        return url('/api/storage/' . ltrim($path, '/'));
    }
}