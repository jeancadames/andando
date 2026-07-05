<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use App\Models\ProviderScheduleCancellation;
use App\Services\Payments\BookingCancellationDecisionService;
use App\Services\Payments\CancelBookingPaymentService;
use App\Services\PushNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ProviderScheduleCancellationController extends Controller
{
    public function __invoke(
        Request $request,
        ProviderExperience $experience,
        ProviderExperienceSchedule $schedule,
        PushNotificationService $pushNotificationService,
        CancelBookingPaymentService $cancelBookingPaymentService
    ): JsonResponse {
        $user = $request->user();
        $provider = $user?->provider;

        if (!$provider || $provider->status !== 'approved') {
            return response()->json([
                'message' => 'No tienes permiso para cancelar este horario.',
            ], 403);
        }

        if ((int) $experience->provider_id !== (int) $provider->id) {
            return response()->json([
                'message' => 'Esta experiencia no pertenece a tu cuenta.',
            ], 403);
        }

        if (
            (int) $schedule->provider_id !== (int) $provider->id ||
            (int) $schedule->provider_experience_id !== (int) $experience->id
        ) {
            return response()->json([
                'message' => 'Este horario no pertenece a esta experiencia.',
            ], 403);
        }

        if (!in_array($schedule->status, ['active', 'paused', 'available'], true)) {
            return response()->json([
                'message' => 'Este horario no se puede cancelar porque su estado actual no lo permite.',
                'current_status' => $schedule->status,
            ], 422);
        }

        if (!$schedule->starts_at) {
            return response()->json([
                'message' => 'Este horario no tiene fecha de inicio configurada.',
            ], 422);
        }

        $validated = $request->validate([
            'reason_type' => [
                'required',
                'string',
                Rule::in([
                    'low_participants',
                    'weather_or_natural_event',
                    'provider_emergency',
                    'operational_issue',
                    'other',
                ]),
            ],
            'reason_description' => [
                'required',
                'string',
                'min:10',
                'max:2000',
            ],
        ]);

        $cancellationPenaltyHours = (int) ($experience->cancellation_penalty_hours ?? 72);

        if ($cancellationPenaltyHours < 0) {
            $cancellationPenaltyHours = 72;
        }

        $policyDeadlineAt = $schedule->starts_at->copy()->subHours($cancellationPenaltyHours);

        $isWithinPolicy = now()->lessThanOrEqualTo($policyDeadlineAt);

        if (!$isWithinPolicy) {
            return response()->json([
                'message' => 'Esta fecha ya está fuera del plazo permitido para cancelación directa. Contacta al equipo de soporte.',
                'requires_support_ticket' => true,
                'support_ticket_placeholder' => true,
                'schedule_id' => $schedule->id,
                'experience_id' => $experience->id,
                'starts_at' => $schedule->starts_at,
                'policy_deadline_at' => $policyDeadlineAt,
                'cancellation_penalty_hours' => $cancellationPenaltyHours,
            ], 409);
        }

        $now = now();
        $affectedBookings = collect();

        DB::transaction(function () use (
            $provider,
            $user,
            $experience,
            $schedule,
            $validated,
            $policyDeadlineAt,
            $cancellationPenaltyHours,
            $now,
            $cancelBookingPaymentService,
            &$affectedBookings
        ): void {
            $bookingsQuery = ProviderBooking::query()
                ->where('provider_id', $provider->id)
                ->where('provider_experience_id', $experience->id)
                ->where('provider_experience_schedule_id', $schedule->id)
                ->whereIn('status', [
                    ProviderBooking::STATUS_PENDING,
                    ProviderBooking::STATUS_CONFIRMED,
                ]);

            $affectedBookings = (clone $bookingsQuery)
                ->with([
                    'user',
                    'experience',
                    'schedule',
                ])
                ->get();

            $bookingsCancelledCount = $affectedBookings->count();

            $cancellationReason = Str::limit(
                $validated['reason_type'] . ': ' . $validated['reason_description'],
                255,
                ''
            );

            $schedule->forceFill([
                'status' => 'cancelled',
                'cancellation_reason' => $cancellationReason,
            ])->save();

            foreach ($affectedBookings as $booking) {
                $cancelBookingPaymentService->cancel(
                    booking: $booking,
                    reason: BookingCancellationDecisionService::REASON_PROVIDER,
                    cancelledBy: ProviderBooking::CANCELLED_BY_PROVIDER,
                );
            }

            ProviderScheduleCancellation::create([
                'provider_id' => $provider->id,
                'provider_experience_id' => $experience->id,
                'provider_experience_schedule_id' => $schedule->id,
                'cancelled_by_user_id' => $user?->id,
                'reason_type' => $validated['reason_type'],
                'reason_description' => $validated['reason_description'],
                'bookings_cancelled_count' => $bookingsCancelledCount,
                'scheduled_start_at' => $schedule->starts_at,
                'policy_deadline_at' => $policyDeadlineAt,
                'cancellation_penalty_hours' => $cancellationPenaltyHours,
                'was_within_policy' => true,
                'cancelled_at' => $now,
            ]);

            $schedule->delete();

            /*
             * TODO:
             * - Crear flujo real de ticket para cancelaciones fuera de política.
             */
        });

        foreach ($affectedBookings as $booking) {
            if (! $booking->user) {
                continue;
            }

            $experienceName = $booking->experience?->title
                ?? $experience->title
                ?? 'tu experiencia';

            $pushNotificationService->sendToUser(
                user: $booking->user,
                title: 'Salida cancelada',
                body: "La salida de {$experienceName} fue cancelada por el afiliado.",
                data: [
                    'type' => 'schedule_cancelled',
                    'booking_id' => (string) $booking->id,
                    'schedule_id' => (string) $schedule->id,
                    'experience_id' => (string) $experience->id,
                    'cancelled_by' => 'provider',
                    'reason_type' => (string) $validated['reason_type'],
                    'role' => 'customer',
                ],
                category: PushNotificationService::CATEGORY_BOOKING,
            );
        }

        return response()->json([
            'message' => 'Horario cancelado correctamente.',
            'schedule_status' => 'cancelled',
            'requires_support_ticket' => false,
        ]);
    }
}