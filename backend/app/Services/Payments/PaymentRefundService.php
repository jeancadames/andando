<?php

namespace App\Services\Payments;

use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use Illuminate\Support\Facades\DB;

class PaymentRefundService
{
    public function __construct(
        private readonly PaymentGatewayManager $gatewayManager,
        private readonly PaymentCalculator $calculator,
    ) {}

    public function refundBooking(
        ProviderBooking $booking,
        PaymentTransaction $transaction,
        float $refundPercent,
        string $reason
    ): PaymentRefund {
        $amount = (float) $transaction->amount;

        $breakdown = match ((int) $refundPercent) {
            100 => $this->calculator->calculateFullRefund($amount),
            0 => $this->calculator->calculateNoRefund($amount),
            default => $this->calculator->calculateCustomerPolicyRefund($amount),
        };

        $refund = PaymentRefund::create([
            'payment_transaction_id' => $transaction->id,
            'provider_booking_id' => $booking->id,
            'user_id' => $booking->user_id,
            'gateway' => config('payments.gateway', 'fake_azul'),
            'environment' => config('payments.environment', 'test'),
            'status' => PaymentRefund::STATUS_PENDING,
            'reason' => $reason,
            'amount' => $breakdown['refund_amount'],
            'currency' => $transaction->currency,
            'refund_percent' => $breakdown['refund_percent'],
            'retained_amount' => $breakdown['retained_amount'],
        ]);

        if ($refund->amount <= 0) {
            $refund->update([
                'status' => PaymentRefund::STATUS_SUCCEEDED,
                'processed_at' => now(),
            ]);

            return $refund;
        }

        $refund->update([
            'status' => PaymentRefund::STATUS_PROCESSING,
        ]);

        $response = $this->gatewayManager->gateway()->refund($refund);

        return DB::transaction(function () use ($refund, $transaction, $booking, $response) {
            if ($response['success'] ?? false) {
                $refund->update([
                    'status' => PaymentRefund::STATUS_SUCCEEDED,
                    'gateway_refund_id' => $response['AzulOrderId'] ?? null,
                    'gateway_response_code' => $response['ResponseCode'] ?? null,
                    'gateway_iso_code' => $response['IsoCode'] ?? null,
                    'gateway_response_message' => $response['ResponseMessage'] ?? null,
                    'raw_response' => $response,
                    'processed_at' => now(),
                ]);

                $transaction->update([
                    'status' => $refund->refund_percent >= 100
                        ? PaymentTransaction::STATUS_REFUNDED
                        : PaymentTransaction::STATUS_PARTIALLY_REFUNDED,
                ]);

                $booking->update([
                    'refund_status' => $refund->status,
                    'refunded_at' => now(),
                ]);

                return $refund;
            }

            $refund->update([
                'status' => PaymentRefund::STATUS_FAILED,
                'gateway_response_code' => $response['ResponseCode'] ?? null,
                'gateway_iso_code' => $response['IsoCode'] ?? null,
                'gateway_response_message' => $response['ResponseMessage'] ?? null,
                'gateway_error_description' => $response['ErrorDescription'] ?? null,
                'raw_response' => $response,
                'processed_at' => now(),
            ]);

            $booking->update([
                'refund_status' => PaymentRefund::STATUS_FAILED,
            ]);

            return $refund;
        });
    }
}