<?php

namespace App\Services\Payments;

use App\Models\ProviderBooking;
use Carbon\CarbonInterface;

class BookingChargeSchedulerService
{
    public function calculateChargeScheduledAt(ProviderBooking $booking): CarbonInterface
    {
        $createdAt = $booking->created_at ?? now();

        $afterFreeCancellationWindow = $createdAt->copy()->addHours(
            (int) config('payments.rules.booking_min_free_cancel_hours', 24)
        );

        $schedule = $booking->schedule;

        if (! $schedule || ! $schedule->starts_at) {
            return $afterFreeCancellationWindow;
        }

        $nonRefundableStartsAt = $this->calculateNonRefundableStartsAt($booking);

        if (now()->greaterThanOrEqualTo($nonRefundableStartsAt)) {
            return now();
        }

        return $afterFreeCancellationWindow->greaterThan($nonRefundableStartsAt)
            ? $afterFreeCancellationWindow
            : $nonRefundableStartsAt;
    }

    private function calculateNonRefundableStartsAt(ProviderBooking $booking): CarbonInterface
    {
        $scheduleStart = $booking->schedule->starts_at;

        $policyType = $booking->cancellation_policy_type;

        return match ($policyType) {
            '24_hours' => $scheduleStart->copy()->subHours(24),
            '48_hours' => $scheduleStart->copy()->subHours(48),
            '72_hours' => $scheduleStart->copy()->subHours(72),
            default => $scheduleStart->copy()->subHours(24),
        };
    }
}