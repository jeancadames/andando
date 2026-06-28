<?php

namespace App\Services\Payments;

use App\Models\BookingClaim;
use App\Models\ProviderExperienceSchedule;
use App\Models\ProviderPayout;

class SchedulePayoutHoldService
{
    public function __construct(
        private readonly ProviderPayoutService $providerPayoutService,
    ) {}

    public function holdByClaim(BookingClaim $claim): void
    {
        $booking = $claim->booking;

        if (! $booking || ! $booking->schedule) {
            return;
        }

        $payout = $this->providerPayoutService->ensurePayoutForSchedule($booking->schedule);

        $payout->update([
            'status' => ProviderPayout::STATUS_ON_HOLD,
            'held_at' => now(),
            'hold_reason' => 'booking_claim_opened',
            'held_by_claim_id' => $claim->id,
        ]);
    }

    public function releaseSchedule(ProviderExperienceSchedule $schedule): void
    {
        $payout = $this->providerPayoutService->ensurePayoutForSchedule($schedule);

        if (! $payout->isOnHold()) {
            return;
        }

        $payout->update([
            'status' => $payout->scheduled_release_at && $payout->scheduled_release_at->isPast()
                ? ProviderPayout::STATUS_READY_TO_PAY
                : ProviderPayout::STATUS_SCHEDULED,
            'released_from_hold_at' => now(),
            'hold_reason' => null,
            'held_by_claim_id' => null,
        ]);
    }

    public function cancelSchedule(ProviderExperienceSchedule $schedule, string $reason = 'claim_resolved_against_provider'): void
    {
        $payout = $this->providerPayoutService->ensurePayoutForSchedule($schedule);

        $payout->update([
            'status' => ProviderPayout::STATUS_CANCELLED,
            'hold_reason' => $reason,
        ]);
    }
}