<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderExperienceSchedule;
use App\Models\ProviderPayout;
use App\Notifications\Payment\CommissionPaidNotification;
use App\Services\PushNotificationService;

class ProviderPayoutService
{

    public function __construct(
        private readonly PushNotificationService $pushNotificationService,
    ) {}

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

            $payout->loadMissing([
                'schedule.experience',
            ]);

            $experienceName = $payout->schedule?->experience?->title
                ?? 'una experiencia';

            $formattedAmount = number_format((float) $payout->net_amount, 2);

            $this->pushNotificationService->sendToUser(
                user: $payout->provider->user,
                title: 'Pago de viaje procesado',
                body: "Tu pago de {$formattedAmount} {$payout->currency} por {$experienceName} fue procesado.",
                data: [
                    'type' => 'payout_paid',
                    'payout_id' => (string) $payout->id,
                    'schedule_id' => (string) $payout->provider_experience_schedule_id,
                    'amount' => (string) $payout->net_amount,
                    'currency' => (string) $payout->currency,
                    'role' => 'provider',
                ],
                category: PushNotificationService::CATEGORY_PAYOUT,
            );
        }
    }

    public function calculateCurrentTotals(ProviderPayout $payout): array
    {
        $transactions = PaymentTransaction::query()
            ->where('provider_experience_schedule_id', $payout->provider_experience_schedule_id)
            ->where('status', PaymentTransaction::STATUS_PAID)
            ->get();

        $grossAmount = round((float) $transactions->sum('amount'), 2);
        $commissionAmount = round(
            (float) $transactions->sum('andando_commission_amount'),
            2
        );

        return [
            'gross_amount' => $grossAmount,
            'commission_rate' => $grossAmount > 0
                ? round($commissionAmount / $grossAmount, 4)
                : 0.0,
            'commission_amount' => $commissionAmount,
            'net_amount' => round((float) $transactions->sum('provider_amount'), 2),
        ];
    }
}
