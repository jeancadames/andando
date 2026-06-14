<?php

namespace App\Http\Controllers\Api\Client;

use Barryvdh\DomPDF\Facade\Pdf;


use App\Http\Controllers\Controller;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class ClientBookingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->markCompletedBookingsForUser($request->user()->id);

        $bookings = ProviderBooking::query()
            ->with([
                'experience.coverPhoto',
                'experience.photos',
                'schedule',
                'review.photos',
                'claim',
            ])
            ->where('user_id', $request->user()->id)
            ->latest('booking_date')
            ->get()
            ->map(function (ProviderBooking $booking) {
                $experience = $booking->experience;
                $schedule = $booking->schedule;

                return [
                    'id' => $booking->id,
                    'experience_id' => $booking->provider_experience_id,
                    'booking_code' => $booking->booking_code,
                    'status' => $booking->status,
                    'experience_title' => $experience?->title ?? 'Experiencia',
                    'location' => $experience?->location,
                    'province' => $experience?->province,
                    'cover_photo_url' => $this->resolveExperienceCoverPhotoUrl($experience),
                    'booking_date' => $booking->booking_date?->toIso8601String(),
                    'starts_at' => $schedule?->starts_at?->toIso8601String()
                        ?? $booking->booking_date?->toIso8601String(),
                    'ends_at' => $schedule?->ends_at?->toIso8601String(),
                    'guests_count' => (int) $booking->guests_count,
                    'unit_price' => (float) $booking->unit_price,
                    'total_amount' => (float) $booking->total_amount,
                    'currency' => $experience?->currency ?? 'DOP',
                    'pickup_point' => $booking->pickup_point
                        ?? $experience?->start_location
                        ?? $experience?->location
                        ?? $experience?->province,
                    'duration' => $experience?->duration,
                    'has_review' => $booking->review !== null,
                    'review_id' => $booking->review?->id,
                    'review_rating' => $booking->review?->rating,
                    'review_comment' => $booking->review?->comment,
                    'has_claim' => $booking->claim !== null,
                    'claim_id' => $booking->claim?->id,
                    'claim_status' => $booking->claim?->status,
                    'review_photos' => $booking->review
                        ? $booking->review->photos->map(fn ($photo) => [
                            'id' => $photo->id,
                            'url' => $photo->photo_url,
                        ])->values()
                        : [],
                ];
            })
            ->values();

        return response()->json([
            'message' => 'Reservas obtenidas correctamente.',
            'data' => $bookings,
        ]);
    }

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
            'pickup_point' => [
                'required',
                'string',
                'max:255',
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

            $pickupPoints = collect($schedule->experience?->pickup_points ?? [])
                ->map(fn ($point) => trim((string) $point))
                ->filter()
                ->values();

            if ($pickupPoints->isEmpty()) {
                abort(422, 'Esta experiencia no tiene puntos de recogida disponibles.');
            }

            if (! $pickupPoints->contains($data['pickup_point'])) {
                abort(422, 'Selecciona un punto de recogida válido.');
}

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

            $booking = ProviderBooking::create([
                'provider_id' => $schedule->provider_id,
                'provider_experience_id' => $schedule->provider_experience_id,
                'provider_experience_schedule_id' => $schedule->id,
                'user_id' => $user->id,
                'booking_code' => $this->generateUniqueBookingCode(),
                'customer_name' => $user->name,
                'customer_phone' => $user->phone ?? null,
                'customer_email' => $user->email,
                'booking_date' => $schedule->starts_at,
                'pickup_point' => $data['pickup_point'],
                'guests_count' => $data['guests_count'],
                'unit_price' => $unitPrice,
                'total_amount' => $totalAmount,
                'provider_earning' => $totalAmount,
                'status' => 'pending',
            ]);

            Conversation::query()
                ->where('customer_user_id', $user->id)
                ->where('provider_id', $booking->provider_id)
                ->where('provider_experience_id', $booking->provider_experience_id)
                ->whereNull('provider_booking_id')
                ->update([
                    'provider_booking_id' => $booking->id,
                ]);

            return $booking;
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

    public function cancel(Request $request, ProviderBooking $booking): JsonResponse
    {
        if ($booking->user_id !== $request->user()->id) {
            abort(403, 'No tienes permiso para cancelar esta reserva.');
        }

        if (in_array($booking->status, ['completed', 'cancelled'], true)) {
            return response()->json([
                'message' => 'Esta reserva ya no puede ser cancelada.',
            ], 422);
        }

        $booking->load('schedule');

        $startsAt = $booking->schedule?->starts_at ?? $booking->booking_date;

        if ($startsAt && $startsAt->lte(now())) {
            return response()->json([
                'message' => 'No puedes cancelar una reserva que ya inició.',
            ], 422);
        }

        $booking->update([
            'status' => 'cancelled',
        ]);

        return response()->json([
            'message' => 'Reserva cancelada correctamente.',
            'data' => [
                'id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'status' => $booking->status,
            ],
        ]);
    }

    /**
     * Descargar comprobante de reserva en PDF.
     */
    public function receipt(
        Request $request,
        ProviderBooking $booking,
    ): Response {
        if ($booking->user_id !== $request->user()->id) {
            abort(403, 'No tienes permiso para acceder a esta reserva.');
        }

        $booking->load([
            'provider',
            'experience.coverPhoto',
            'experience.photos',
            'schedule',
        ]);

        $experience = $booking->experience;
        $schedule = $booking->schedule;
        $provider = $booking->provider;

        $startsAt = $schedule?->starts_at ?? $booking->booking_date;

        $logoPath = public_path('images/andando_logo.png');

        $coverPath = null;

        $coverPhoto = $experience?->coverPhoto
            ?? $experience?->photos?->sortBy('sort_order')->first();

        if ($coverPhoto && $coverPhoto->path) {
            $possiblePath = storage_path('app/public/' . ltrim($coverPhoto->path, '/'));

            if (file_exists($possiblePath)) {
                $coverPath = $possiblePath;
            }
        }

        $includedItems = $experience?->included ?? [];

        $pickupPointText = $booking->pickup_point
            ?? $experience?->start_location
            ?? $experience?->location
            ?? $experience?->province
            ?? 'No especificado';

        $cancellationPolicyText = $this->formatCancellationPolicy(
            $experience?->cancellation_policy
        );
        
        $html = view('pdf.booking-receipt', [
            'booking' => $booking,
            'experience' => $experience,
            'schedule' => $schedule,
            'provider' => $provider,
            'startsAt' => $startsAt,
            'logoPath' => file_exists($logoPath) ? $logoPath : null,
            'coverPath' => $coverPath,
            'includedItems' => is_array($includedItems) ? $includedItems : [],
            'pickupPointText' => $pickupPointText,
            'cancellationPolicyText' => $cancellationPolicyText,
        ])->render();

        $pdf = Pdf::loadHTML($html)
            ->setPaper('letter', 'portrait');

        return $pdf->download(
            'comprobante-' . $booking->booking_code . '.pdf'
        );
    }

    private function markCompletedBookingsForUser(int $userId): void
    {
        $bookings = ProviderBooking::query()
            ->with(['schedule', 'experience'])
            ->where('user_id', $userId)
            ->whereIn('status', ['pending', 'confirmed'])
            ->get();

        foreach ($bookings as $booking) {
            $startsAt = $booking->schedule?->starts_at ?? $booking->booking_date;

            if (! $startsAt) {
                continue;
            }

            $endsAt = $booking->schedule?->ends_at;

            if (! $endsAt) {
                $durationHours = $this->extractDurationHours(
                    $booking->experience?->duration
                );

                $endsAt = $startsAt->copy()->addHours($durationHours);
            }

            if ($endsAt->lte(now())) {
                $booking->update([
                    'status' => 'completed',
                ]);
            }
        }
    }

    private function extractDurationHours(?string $duration): int
    {
        if (! $duration) {
            return 8;
        }

        if (preg_match('/(\d+)/', $duration, $matches)) {
            return max(1, (int) $matches[1]);
        }

        return 8;
    }

    private function generateUniqueBookingCode(): string
    {
        do {
            $code = 'ANDO-' . strtoupper(Str::random(8));
        } while (
            ProviderBooking::query()
                ->where('booking_code', $code)
                ->exists()
        );

        return $code;
    }

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

        return url('/api/public-files/' . ltrim($path, '/'));
    }

    private function formatCancellationPolicy(?string $policy): string
    {
        $normalized = trim((string) $policy);

        return match ($normalized) {
            'free_24h' => 'Cancelación gratuita hasta 24 horas antes del inicio de la experiencia. Después de ese plazo, la reserva no será reembolsable salvo decisión del proveedor.',
            'free_48h' => 'Cancelación gratuita hasta 48 horas antes del inicio de la experiencia. Después de ese plazo, la reserva no será reembolsable salvo decisión del proveedor.',
            'free_72h' => 'Cancelación gratuita hasta 72 horas antes del inicio de la experiencia. Después de ese plazo, la reserva no será reembolsable salvo decisión del proveedor.',
            'no_refund' => 'Esta experiencia no permite reembolsos después de confirmada la reserva, salvo cancelación realizada por el proveedor.',
            'flexible' => 'Política flexible: puedes solicitar cancelación o cambio de fecha sujeto a disponibilidad y aprobación del proveedor.',
            default => $normalized !== ''
                ? $normalized
                : 'Cancelación sujeta a las políticas del proveedor y disponibilidad de la experiencia.',
        };
    }

}