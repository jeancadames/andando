<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderExperienceSchedule;
use App\Models\ProviderPayout;
use App\Notifications\Payment\CommissionPaidNotification;

class ProviderPayoutService
{
    public function ensurePayoutForSchedule(ProviderExperienceSchedule $schedule): ProviderPayout
    {
        return ProviderPayout::firstOrCreate(
            [
                'provider_experience_schedule_id' => $schedule->id,
            ],
            [
                'provider_id' => $schedule->provider_id,
                'status' => ProviderPayout::STATUS_NOT_READY,
                'currency' => $schedule->currency ?? 'DOP',
            ]
        );
    }

    public function markScheduleCompleted(ProviderExperienceSchedule $schedule): ProviderPayout
    {
        $payout = $this->ensurePayoutForSchedule($schedule);

        $releaseDays = (int) config('payments.rules.provider_payout_release_days', 3);

        $payout->update([
            'status' => ProviderPayout::STATUS_SCHEDULED,
            'scheduled_release_at' => now()->addDays($releaseDays),
        ]);

        return $payout;
    }

    public function markReadyToPay(ProviderPayout $payout): void
    {
        if ($payout->isOnHold() || $payout->isPaid()) {
            return;
        }

        $payout->update([
            'status' => ProviderPayout::STATUS_READY_TO_PAY,
        ]);
    }

    public function markPaid(ProviderPayout $payout, ?string $externalReference = null): void
    {
        if ($payout->isPaid()) {
            return;
        }

        $totals = $this->calculateCurrentTotals($payout);

        $payout->update([
            'status' => ProviderPayout::STATUS_PAID,
            'gross_amount' => $totals['gross_amount'],
            'commission_rate' => $totals['commission_rate'],
            'commission_amount' => $totals['commission_amount'],
            'net_amount' => $totals['net_amount'],
            'released_at' => now(),
            'external_reference' => $externalReference,
        ]);

        $payout->refresh();
        $payout->loadMissing('provider.user');

        if ($payout->provider?->user) {
            $payout->provider->user->notify(
                new CommissionPaidNotification($payout)
            );
        }
    }

    public function calculateCurrentTotals(ProviderPayout $payout): array
    {
        $transactions = PaymentTransaction::query()
            ->where('provider_experience_schedule_id', $payout->provider_experience_schedule_id)
            ->where('status', PaymentTransaction::STATUS_PAID)
            ->get();

        return [
            'gross_amount' => round((float) $transactions->sum('amount'), 2),
            'commission_rate' => (float) config('payments.rules.andando_commission_rate', 0.15),
            'commission_amount' => round((float) $transactions->sum('andando_commission_amount'), 2),
            'net_amount' => round((float) $transactions->sum('provider_amount'), 2),
        ];
    }
}