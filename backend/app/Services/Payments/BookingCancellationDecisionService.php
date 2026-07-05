<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;

class BookingCancellationDecisionService
{
    public const REASON_CUSTOMER = 'customer';
    public const REASON_PROVIDER = 'provider';
    public const REASON_WEATHER = 'weather';
    public const REASON_FORCE_MAJEURE = 'force_majeure';
    public const REASON_ADMIN = 'admin';
    public const REASON_CLAIM = 'claim';

    public function decide(ProviderBooking $booking, string $reason): array
    {
        $paidTransaction = $booking->paymentTransactions()
            ->where('status', PaymentTransaction::STATUS_PAID)
            ->latest()
            ->first();

        if (! $paidTransaction) {
            return [
                'should_refund' => false,
                'refund_percent' => 0,
                'refund_reason' => null,
                'should_cancel_payment_transaction' => true,
                'should_cancel_payout' => true,
                'should_hold_schedule_payout' => false,
                'notes' => 'Reserva cancelada antes de cobro.',
            ];
        }

        if (
            $reason === self::REASON_CUSTOMER
            && $this->isWithinInitialFreeCancellationWindow($booking)
        ) {
            return [
                'should_refund' => true,
                'refund_percent' => 100,
                'refund_reason' => 'customer_free_cancellation_window',
                'should_cancel_payment_transaction' => false,
                'should_cancel_payout' => true,
                'should_hold_schedule_payout' => false,
                'notes' => 'Cliente cancela dentro de las primeras 24 horas. Si el cobro ya fue ejecutado, aplica devolución completa.',
            ];
        }

        if (in_array($reason, [
            self::REASON_PROVIDER,
            self::REASON_WEATHER,
            self::REASON_FORCE_MAJEURE,
            self::REASON_ADMIN,
            self::REASON_CLAIM,
        ], true)) {
            return [
                'should_refund' => true,
                'refund_percent' => 100,
                'refund_reason' => $reason,
                'should_cancel_payment_transaction' => false,
                'should_cancel_payout' => true,
                'should_hold_schedule_payout' => false,
                'notes' => 'Devolución completa por causa no atribuible al cliente.',
            ];
        }

        if ($this->isWithinCustomerRefundPolicy($booking)) {
            return [
                'should_refund' => true,
                'refund_percent' => (float) config('payments.rules.customer_policy_refund_percent', 95),
                'refund_reason' => 'customer_policy',
                'should_cancel_payment_transaction' => false,
                'should_cancel_payout' => true,
                'should_hold_schedule_payout' => false,
                'notes' => 'Cliente cancela dentro del período permitido.',
            ];
        }

        return [
            'should_refund' => false,
            'refund_percent' => 0,
            'refund_reason' => 'customer_no_refund',
            'should_cancel_payment_transaction' => false,
            'should_cancel_payout' => false,
            'should_hold_schedule_payout' => false,
            'notes' => 'Cliente cancela fuera del período permitido.',
        ];
    }

    private function isWithinCustomerRefundPolicy(ProviderBooking $booking): bool
    {
        if (! $booking->schedule || ! $booking->schedule->starts_at) {
            return false;
        }

        $nonRefundableStartsAt = match ($booking->cancellation_policy_type) {
            '24_hours' => $booking->schedule->starts_at->copy()->subHours(24),
            '48_hours' => $booking->schedule->starts_at->copy()->subHours(48),
            '72_hours' => $booking->schedule->starts_at->copy()->subHours(72),
            default => $booking->schedule->starts_at->copy()->subHours(24),
        };

        return now()->lessThan($nonRefundableStartsAt);
    }

    private function isWithinInitialFreeCancellationWindow(ProviderBooking $booking): bool
    {
        if (! $booking->created_at) {
            return false;
        }

        $freeCancellationHours = (int) config(
            'payments.rules.booking_min_free_cancel_hours',
            24
        );

        return $booking->created_at
            ->copy()
            ->addHours($freeCancellationHours)
            ->gt(now());
    }
}