<?php

namespace App\Services;

use App\Models\Provider;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use App\Services\Payments\BookingCancellationDecisionService;
use App\Services\Payments\CancelBookingPaymentService;
use Illuminate\Support\Facades\DB;

/**
 * Centraliza la cancelación en cascada cuando se suspende un afiliado
 * o cuando se rechaza/cancela una experiencia desde el panel admin.
 *
 * Estas reglas son la fuente única de verdad: si cambian, se cambian aquí
 * y aplican tanto a la suspensión de cuenta como al rechazo de una experiencia.
 *
 * IMPORTANTE: estos métodos NO abren transacción propia. El controlador que
 * los llama es el dueño de la transacción, para que el cambio de estado del
 * proveedor/experiencia y la cascada sean atómicos (todo o nada).
 */
class ProviderSuspensionService
{
    public function __construct(
        private readonly PushNotificationService $pushNotificationService,
        private readonly CancelBookingPaymentService $cancelBookingPaymentService,
    ) {}

    /**
     * Cancela TODA la operación de un proveedor (al suspender la cuenta):
     *  - experiencias                -> rejected + is_active = false
     *  - bookings pending|confirmed  -> cancelled + refund 100% si estaban pagadas
     *  - schedules active|paused     -> cancelled
     *
     * No toca schedules/bookings completed (ya ocurrieron).
     */
    public function cancelProviderOperations(Provider $provider): void
    {
        // Experiencias: todas pasan a rechazadas e inactivas.
        ProviderExperience::where('provider_id', $provider->id)
            ->update(['status' => 'rejected', 'is_active' => false]);

        // Reservas pendientes o confirmadas -> canceladas usando el flujo financiero.
        // IMPORTANTE: esto debe ocurrir antes de soft-deletear schedules para que
        // CancelBookingPaymentService pueda acceder a $booking->schedule.
        $bookings = ProviderBooking::query()
            ->with([
                'user',
                'experience',
                'schedule',
            ])
            ->where('provider_id', $provider->id)
            ->whereIn('status', [
                ProviderBooking::STATUS_PENDING,
                ProviderBooking::STATUS_CONFIRMED,
            ])
            ->get();

        if ($bookings->isNotEmpty()) {
            foreach ($bookings as $booking) {
                $this->cancelBookingPaymentService->cancel(
                    booking: $booking,
                    reason: BookingCancellationDecisionService::REASON_ADMIN,
                    cancelledBy: ProviderBooking::CANCELLED_BY_ADMIN,
                );

                // Conservamos una razón operativa más específica para auditoría.
                $booking->forceFill([
                    'cancellation_reason' => 'provider_suspended_by_admin',
                ])->save();
            }

            DB::afterCommit(function () use ($bookings): void {
                foreach ($bookings as $booking) {
                    if (! $booking->user) {
                        continue;
                    }

                    $experienceName = $booking->experience?->title
                        ?? 'tu experiencia';

                    $this->pushNotificationService->sendToUser(
                        user: $booking->user,
                        title: 'Salida cancelada',
                        body: "La salida de {$experienceName} fue cancelada por administración.",
                        data: [
                            'type' => 'schedule_cancelled',
                            'booking_id' => (string) $booking->id,
                            'schedule_id' => (string) $booking->provider_experience_schedule_id,
                            'experience_id' => (string) $booking->provider_experience_id,
                            'cancelled_by' => 'admin',
                            'reason_type' => 'provider_suspended',
                            'role' => 'customer',
                        ],
                        category: PushNotificationService::CATEGORY_BOOKING,
                    );
                }
            });
        }

        // Salidas/horarios disponibles o pausados -> cancelados y ocultos.
        // Se hace después de cancelar bookings para no romper relaciones usadas por pagos/payouts.
        ProviderExperienceSchedule::where('provider_id', $provider->id)
            ->whereIn('status', ['active', 'paused'])
            ->update(['status' => 'cancelled', 'deleted_at' => now()]);
    }

    /**
     * Cancela una experiencia concreta y su operación asociada
     * (al rechazar/cancelar la experiencia desde el panel):
     *  - la experiencia              -> rejected + is_active = false
     *  - bookings pending|confirmed  -> cancelled + refund 100% si estaban pagadas
     *  - schedules active|paused     -> cancelled
     */
    public function cancelExperienceOperations(ProviderExperience $experience): void
    {
        $experience->update(['status' => 'rejected', 'is_active' => false]);

        // Reservas pendientes o confirmadas -> canceladas usando el flujo financiero.
        // IMPORTANTE: esto debe ocurrir antes de soft-deletear schedules.
        $bookings = ProviderBooking::query()
            ->with([
                'user',
                'experience',
                'schedule',
            ])
            ->where('provider_experience_id', $experience->id)
            ->whereIn('status', [
                ProviderBooking::STATUS_PENDING,
                ProviderBooking::STATUS_CONFIRMED,
            ])
            ->get();

        if ($bookings->isNotEmpty()) {
            foreach ($bookings as $booking) {
                $this->cancelBookingPaymentService->cancel(
                    booking: $booking,
                    reason: BookingCancellationDecisionService::REASON_ADMIN,
                    cancelledBy: ProviderBooking::CANCELLED_BY_ADMIN,
                );

                // Conservamos una razón operativa más específica para auditoría.
                $booking->forceFill([
                    'cancellation_reason' => 'experience_rejected_by_admin',
                ])->save();
            }

            DB::afterCommit(function () use ($bookings, $experience): void {
                foreach ($bookings as $booking) {
                    if (! $booking->user) {
                        continue;
                    }

                    $experienceName = $booking->experience?->title
                        ?? $experience->title
                        ?? 'tu experiencia';

                    $this->pushNotificationService->sendToUser(
                        user: $booking->user,
                        title: 'Salida cancelada',
                        body: "La salida de {$experienceName} fue cancelada por administración.",
                        data: [
                            'type' => 'schedule_cancelled',
                            'booking_id' => (string) $booking->id,
                            'schedule_id' => (string) $booking->provider_experience_schedule_id,
                            'experience_id' => (string) $booking->provider_experience_id,
                            'cancelled_by' => 'admin',
                            'reason_type' => 'experience_rejected',
                            'role' => 'customer',
                        ],
                        category: PushNotificationService::CATEGORY_BOOKING,
                    );
                }
            });
        }

        ProviderExperienceSchedule::where('provider_experience_id', $experience->id)
            ->whereIn('status', ['active', 'paused'])
            ->update(['status' => 'cancelled', 'deleted_at' => now()]);
    }

    /**
     * Al reactivar la cuenta: las experiencias rechazadas vuelven a borrador
     * para que el afiliado decida si las publica de nuevo.
     *
     * Los schedules y bookings cancelados NO se revierten (siguen cancelados).
     */
    public function restoreProviderExperiencesToDraft(Provider $provider): void
    {
        ProviderExperience::where('provider_id', $provider->id)
            ->where('status', 'rejected')
            ->update(['status' => 'draft', 'published_at' => null]);
    }
}