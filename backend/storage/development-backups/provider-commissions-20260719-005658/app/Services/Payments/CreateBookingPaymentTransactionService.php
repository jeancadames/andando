<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use Illuminate\Support\Str;

class CreateBookingPaymentTransactionService
{
    public function __construct(
        private readonly PaymentCalculator $calculator,
        private readonly BookingChargeSchedulerService $scheduler,
    ) {}

    public function createForBooking(ProviderBooking $booking): PaymentTransaction
    {
        $booking->loadMissing('provider:id,commission_rate');

        $amount = (float) $booking->total_amount;
        $commissionRate = $booking->provider?->commissionRate()
            ?? $this->calculator->commissionRate();
        $breakdown = $this->calculator->calculateChargeBreakdown(
            $amount,
            $commissionRate
        );
        $chargeScheduledAt = $this->scheduler->calculateChargeScheduledAt($booking);

        $transaction = PaymentTransaction::create([
            'provider_booking_id' => $booking->id,
            'provider_experience_schedule_id' => $booking->provider_experience_schedule_id,
            'user_id' => $booking->user_id,
            'provider_id' => $booking->provider_id,
            'customer_payment_method_id' => $booking->customer_payment_method_id,

            'gateway' => config('payments.gateway', 'fake_azul'),
            'environment' => config('payments.environment', 'test'),
            'type' => PaymentTransaction::TYPE_CHARGE,
            'status' => PaymentTransaction::STATUS_SCHEDULED,

            'amount' => $amount,
            'currency' => 'DOP',
            'itbis_amount' => 0,

            'commission_rate' => $breakdown['commission_rate'],
            'andando_commission_amount' => $breakdown['commission_amount'],
            'provider_amount' => $breakdown['provider_amount'],

            'charge_scheduled_at' => $chargeScheduledAt,

            'idempotency_key' => 'booking-charge-' . $booking->id . '-' . Str::uuid(),
        ]);

        $booking->update([
            'provider_earning' => $breakdown['provider_amount'],
            'payment_status' => PaymentTransaction::STATUS_SCHEDULED,
            'charge_scheduled_at' => $chargeScheduledAt,
        ]);

        return $transaction;
    }
}
