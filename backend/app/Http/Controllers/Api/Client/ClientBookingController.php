<?php

namespace App\Http\Controllers\Api\Client;

use Barryvdh\DomPDF\Facade\Pdf;

use App\Models\CustomerPaymentMethod;
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

                    'includes_transport' => (bool) ($experience?->includes_transport ?? false),

                    'experience_address' => $experience?->experience_address,
                    'experience_latitude' => $experience?->experience_latitude !== null
                        ? (float) $experience->experience_latitude
                        : null,
                    'experience_longitude' => $experience?->experience_longitude !== null
                        ? (float) $experience->experience_longitude
                        : null,

                    'pickup_point' => $booking->pickup_point,

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
                'nullable',
                'string',
                'max:255',
            ],
        ]);

        $user = $request->user();

        $defaultPaymentMethod = CustomerPaymentMethod::query()
            ->where('user_id', $user->id)
            ->where('is_default', true)
            ->first();

        if (! $defaultPaymentMethod) {
            return response()->json([
                'message' => 'Debes registrar una tarjeta principal antes de realizar una reserva.',
                'code' => 'CARD_REQUIRED',
            ], 422);
        }

        $booking = DB::transaction(function () use ($data, $user) {
            $schedule = ProviderExperienceSchedule::query()
                ->with('experience.provider')
                ->where('id', $data['provider_experience_schedule_id'])
                ->where('status', 'active')
                ->lockForUpdate()
                ->firstOrFail();

            $experience = $schedule->experience;

            if (! $experience) {
                abort(422, 'La experiencia no está disponible.');
            }

            $includesTransport = (bool) $experience->includes_transport;

            if ($includesTransport) {
                $pickupPoints = collect($experience->mapPickupPoints ?? [])
                    ->map(fn ($point) => trim((string) $point->name))
                    ->filter()
                    ->values();

                if ($pickupPoints->isEmpty()) {
                    abort(422, 'Esta experiencia no tiene puntos de recogida disponibles.');
                }

                $selectedPickupPoint = trim((string) ($data['pickup_point'] ?? ''));

                if ($selectedPickupPoint === '') {
                    abort(422, 'Selecciona un punto de recogida.');
                }

                if (! $pickupPoints->contains($selectedPickupPoint)) {
                    abort(422, 'Selecciona un punto de recogida válido.');
                }
            }

            $reservedGuests = ProviderBooking::query()
                ->where('provider_experience_schedule_id', $schedule->id)
                ->whereIn('status', ['pending', 'confirmed'])
                ->sum('guests_count');

            $availableSpots = $schedule->capacity - $reservedGuests;

            if ($data['guests_count'] > $availableSpots) {
                abort(422, 'No hay cupos suficientes para esta fecha.');
            }

            $unitPrice = $schedule->price ?? $experience->price;
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
                'pickup_point' => $includesTransport
                    ? trim((string) ($data['pickup_point'] ?? ''))
                    : null,
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

    public function cancellationPreview(Request $request, ProviderBooking $booking): JsonResponse
    {
        if ($booking->user_id !== $request->user()->id) {
            abort(403, 'No tienes permiso para consultar esta reserva.');
        }

        if (in_array($booking->status, ['completed', 'cancelled'], true)) {
            return response()->json([
                'message' => 'Esta reserva ya no puede ser cancelada.',
                'data' => [
                    'can_cancel' => false,
                ],
            ], 422);
        }

        $booking->load(['schedule', 'experience']);

        $startsAt = $booking->schedule?->starts_at ?? $booking->booking_date;

        if ($startsAt && $startsAt->lte(now())) {
            return response()->json([
                'message' => 'No puedes cancelar una reserva que ya inició.',
                'data' => [
                    'can_cancel' => false,
                ],
            ], 422);
        }

        return response()->json([
            'message' => 'Vista previa de cancelación generada correctamente.',
            'data' => $this->buildCancellationPreviewData($booking),
        ]);
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

        $booking->load(['schedule', 'experience']);

        $startsAt = $booking->schedule?->starts_at ?? $booking->booking_date;

        if ($startsAt && $startsAt->lte(now())) {
            return response()->json([
                'message' => 'No puedes cancelar una reserva que ya inició.',
            ], 422);
        }

        $preview = $this->buildCancellationPreviewData($booking);

        $booking->update([
            'status' => 'cancelled',
            'cancelled_at' => now(),
            'cancellation_policy_type' => $preview['policy_type'],
            'refund_amount' => $preview['refund_amount'],
            'administrative_fee_amount' => $preview['administrative_fee_amount'],
            'refund_percentage' => $preview['refund_percentage'],
        ]);

        return response()->json([
            'message' => 'Reserva cancelada correctamente.',
            'data' => [
                'id' => $booking->id,
                'booking_code' => $booking->booking_code,
                'status' => $booking->status,
                'cancellation_policy_type' => $booking->cancellation_policy_type,
                'refund_amount' => (float) $booking->refund_amount,
                'administrative_fee_amount' => (float) $booking->administrative_fee_amount,
                'refund_percentage' => (int) $booking->refund_percentage,
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

    private function buildCancellationPreviewData(ProviderBooking $booking): array
    {
        $booking->loadMissing(['schedule', 'experience']);

        $startsAt = $booking->schedule?->starts_at ?? $booking->booking_date;

        $totalAmount = (float) $booking->total_amount;
        $policy = $booking->experience?->cancellation_policy;

        $penaltyHours = $this->getCancellationPenaltyHours($policy);

        $isNoRefundPolicy = trim((string) $policy) === 'no_refund';

        $isInsideProviderPenaltyWindow = false;

        if ($isNoRefundPolicy) {
            $isInsideProviderPenaltyWindow = true;
        } elseif ($startsAt) {
            $hoursUntilExperience = now()->diffInHours($startsAt, false);
            $isInsideProviderPenaltyWindow = $hoursUntilExperience <= $penaltyHours;
        }

        $isWithinFirst24Hours = $booking->created_at
            ? $booking->created_at->copy()->addHours(24)->gt(now())
            : false;

        if ($isInsideProviderPenaltyWindow) {
            return [
                'can_cancel' => true,
                'policy_type' => 'no_refund',
                'total_amount' => $totalAmount,
                'refund_amount' => 0,
                'administrative_fee_amount' => 0,
                'refund_percentage' => 0,
                'message' => 'Esta reserva se encuentra dentro del período no reembolsable de la experiencia. No aplica reembolso.',
            ];
        }

        if ($isWithinFirst24Hours) {
            return [
                'can_cancel' => true,
                'policy_type' => 'free_refund',
                'total_amount' => $totalAmount,
                'refund_amount' => $totalAmount,
                'administrative_fee_amount' => 0,
                'refund_percentage' => 100,
                'message' => 'Tu reserva aún se encuentra dentro de las primeras 24 horas. Puedes cancelar sin penalidad.',
            ];
        }

        $administrativeFee = round($totalAmount * 0.05, 2);
        $refundAmount = round($totalAmount - $administrativeFee, 2);

        return [
            'can_cancel' => true,
            'policy_type' => 'partial_refund',
            'total_amount' => $totalAmount,
            'refund_amount' => $refundAmount,
            'administrative_fee_amount' => $administrativeFee,
            'refund_percentage' => 95,
            'message' => 'Puedes cancelar esta reserva. AndanDO retendrá un 5% por costos administrativos y reembolsará el 95% restante.',
        ];
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

    private function getCancellationPenaltyHours(?string $policy): int
    {
        return match (trim((string) $policy)) {
            'free_24h' => 24,
            'free_48h' => 48,
            'free_72h' => 72,
            'free_5d' => 120,
            'no_refund' => PHP_INT_MAX,
            default => 24,
        };
    }

}