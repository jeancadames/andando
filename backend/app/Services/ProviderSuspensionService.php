<?php

namespace App\Services;

use App\Models\Provider;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use Illuminate\Support\Facades\DB;
use App\Services\PushNotificationService;

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
    ) {}
    /**
     * Cancela TODA la operación de un proveedor (al suspender la cuenta):
     *  - experiencias                -> rejected + is_active = false
     *  - schedules active|paused     -> cancelled
     *  - bookings pending|confirmed  -> cancelled
     *
     * No toca schedules/bookings completed (ya ocurrieron).
     */
    public function cancelProviderOperations(Provider $provider): void
    {
        // Experiencias: todas pasan a rechazadas e inactivas.
        ProviderExperience::where('provider_id', $provider->id)
            ->update(['status' => 'rejected', 'is_active' => false]);

        // Salidas/horarios disponibles o pausados -> cancelados y ocultos.
        // Se marca deleted_at (soft delete) para que el afiliado no las vea.
        ProviderExperienceSchedule::where('provider_id', $provider->id)
            ->whereIn('status', ['active', 'paused'])
            ->update(['status' => 'cancelled', 'deleted_at' => now()]);

        // Reservas pendientes o confirmadas -> canceladas.
        $bookings = ProviderBooking::query()
            ->with([
                'user',
                'experience',
                'schedule',
            ])
            ->where('provider_id', $provider->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->get();

        if ($bookings->isNotEmpty()) {
            ProviderBooking::whereIn('id', $bookings->pluck('id'))
                ->update([
                    'status' => 'cancelled',
                    'cancelled_by' => ProviderBooking::CANCELLED_BY_ADMIN,
                    'cancellation_reason' => 'provider_suspended_by_admin',
                    'cancelled_at' => now(),
                ]);

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
    }

    /**
     * Cancela una experiencia concreta y su operación asociada
     * (al rechazar/cancelar la experiencia desde el panel):
     *  - la experiencia              -> rejected + is_active = false
     *  - sus schedules active|paused -> cancelled
     *  - sus bookings pending|confirmed -> cancelled
     */
    public function cancelExperienceOperations(ProviderExperience $experience): void
    {
        $experience->update(['status' => 'rejected', 'is_active' => false]);

        ProviderExperienceSchedule::where('provider_experience_id', $experience->id)
            ->whereIn('status', ['active', 'paused'])
            ->update(['status' => 'cancelled', 'deleted_at' => now()]);

        $bookings = ProviderBooking::query()
            ->with([
                'user',
                'experience',
                'schedule',
            ])
            ->where('provider_experience_id', $experience->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->get();

        if ($bookings->isNotEmpty()) {
            ProviderBooking::whereIn('id', $bookings->pluck('id'))
                ->update([
                    'status' => 'cancelled',
                    'cancelled_by' => ProviderBooking::CANCELLED_BY_ADMIN,
                    'cancellation_reason' => 'experience_rejected_by_admin',
                    'cancelled_at' => now(),
                ]);

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
