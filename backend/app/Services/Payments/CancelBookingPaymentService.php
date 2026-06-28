<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use App\Models\ProviderPayout;
use Illuminate\Support\Facades\DB;

class CancelBookingPaymentService
{
    public function __construct(
        private readonly BookingCancellationDecisionService $decisionService,
        private readonly PaymentRefundService $refundService,
        private readonly ProviderPayoutService $providerPayoutService,
    ) {}

    public function cancel(ProviderBooking $booking, string $reason, string $cancelledBy): void
    {
        DB::transaction(function () use ($booking, $reason, $cancelledBy) {
            $decision = $this->decisionService->decide($booking, $reason);

            $paidTransaction = $booking->paymentTransactions()
                ->where('status', PaymentTransaction::STATUS_PAID)
                ->latest()
                ->first();

            if (! $paidTransaction) {
                $booking->paymentTransactions()
                    ->where('status', PaymentTransaction::STATUS_SCHEDULED)
                    ->update([
                        'status' => PaymentTransaction::STATUS_CANCELLED,
                    ]);
            }

            $booking->update([
                'status' => ProviderBooking::STATUS_CANCELLED,
                'payment_status' => $paidTransaction
                    ? $booking->payment_status
                    : PaymentTransaction::STATUS_CANCELLED,
                'cancelled_by' => $cancelledBy,
                'cancellation_reason' => $reason,
                'cancelled_at' => now(),
            ]);

            if ($decision['should_cancel_payout'] ?? false) {
                $payout = $this->providerPayoutService->ensurePayoutForSchedule($booking->schedule);

                $payout->update([
                    'status' => ProviderPayout::STATUS_CANCELLED,
                    'notes' => $decision['notes'] ?? null,
                ]);
            }

            if (($decision['should_refund'] ?? false) && $paidTransaction) {
                $this->refundService->refundBooking(
                    booking: $booking,
                    transaction: $paidTransaction,
                    refundPercent: (float) $decision['refund_percent'],
                    reason: (string) $decision['refund_reason'],
                );
            }
        });
    }
}