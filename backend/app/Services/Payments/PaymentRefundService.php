<?php

namespace App\Services\Payments;

use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use App\Services\PushNotificationService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class PaymentRefundService
{
    public function __construct(
        private readonly PaymentGatewayManager $gatewayManager,
        private readonly PaymentCalculator $calculator,
        private readonly PushNotificationService $pushNotificationService,
    ) {}

    public function refundBooking(
        ProviderBooking $booking,
        PaymentTransaction $transaction,
        float $refundPercent,
        string $reason
    ): PaymentRefund {
        $existingRefund = PaymentRefund::query()
            ->where('payment_transaction_id', $transaction->id)
            ->where('provider_booking_id', $booking->id)
            ->whereIn('status', [
                PaymentRefund::STATUS_PENDING,
                PaymentRefund::STATUS_PROCESSING,
                PaymentRefund::STATUS_SUCCEEDED,
            ])
            ->latest()
            ->first();

        if ($existingRefund) {
            Log::info('Existing payment refund reused to avoid duplicate refund.', [
                'refund_id' => $existingRefund->id,
                'booking_id' => $booking->id,
                'payment_transaction_id' => $transaction->id,
                'status' => $existingRefund->status,
                'reason' => $reason,
                'requested_refund_percent' => $refundPercent,
            ]);

            if ($existingRefund->status === PaymentRefund::STATUS_SUCCEEDED) {
                $transaction->update([
                    'status' => $existingRefund->refund_percent >= 100
                        ? PaymentTransaction::STATUS_REFUNDED
                        : PaymentTransaction::STATUS_PARTIALLY_REFUNDED,
                ]);

                $booking->update([
                    'payment_status' => $existingRefund->refund_percent >= 100
                        ? ProviderBooking::PAYMENT_STATUS_REFUNDED
                        : ProviderBooking::PAYMENT_STATUS_PARTIALLY_REFUNDED,
                    'refund_status' => $existingRefund->status,
                    'refund_amount' => $existingRefund->amount,
                    'refund_percentage' => (int) round((float) $existingRefund->refund_percent),
                    'administrative_fee_amount' => $existingRefund->retained_amount,
                    'refunded_at' => $existingRefund->processed_at ?? now(),
                ]);
            }

            return $existingRefund;
        }

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

        try {
            $response = $this->gatewayManager->gateway()->refund($refund);
        } catch (Throwable $e) {
            $refund->update([
                'status' => PaymentRefund::STATUS_FAILED,
                'gateway_error_description' => $e->getMessage(),
                'processed_at' => now(),
            ]);

            $booking->update([
                'refund_status' => PaymentRefund::STATUS_FAILED,
            ]);

            Log::warning('Payment refund failed and requires manual review.', [
                'refund_id' => $refund->id,
                'booking_id' => $booking->id,
                'payment_transaction_id' => $transaction->id,
                'amount' => $refund->amount,
                'currency' => $refund->currency,
                'reason' => $reason,
                'exception_class' => get_class($e),
                'exception_message' => $e->getMessage(),
            ]);

            return $refund;
        }

        return DB::transaction(function () use ($refund, $transaction, $booking, $response, $reason) {
            if ($response['success'] ?? false) {
                $refund->update([
                    'status' => PaymentRefund::STATUS_SUCCEEDED,

                    'gateway_refund_id' => $response['AzulOrderId'] ?? null,
                    'gateway_response_code' => $response['ResponseCode'] ?? null,
                    'gateway_iso_code' => $response['IsoCode'] ?? null,
                    'gateway_response_message' => $response['ResponseMessage'] ?? null,
                    'gateway_error_description' => $response['ErrorDescription'] ?? null,

                    'raw_request' => $response['raw_request'] ?? null,
                    'raw_response' => $response['raw_response'] ?? $response,

                    'processed_at' => now(),
                ]);

                $transaction->update([
                    'status' => $refund->refund_percent >= 100
                        ? PaymentTransaction::STATUS_REFUNDED
                        : PaymentTransaction::STATUS_PARTIALLY_REFUNDED,
                ]);

                $booking->update([
                    'payment_status' => $refund->refund_percent >= 100
                        ? ProviderBooking::PAYMENT_STATUS_REFUNDED
                        : ProviderBooking::PAYMENT_STATUS_PARTIALLY_REFUNDED,
                    'refund_status' => $refund->status,
                    'refund_amount' => $refund->amount,
                    'refund_percentage' => (int) round((float) $refund->refund_percent),
                    'administrative_fee_amount' => $refund->retained_amount,
                    'refunded_at' => now(),
                ]);

                $refund->loadMissing([
                    'booking.user',
                    'booking.experience',
                ]);

                if ($refund->amount > 0 && $refund->booking?->user) {
                    $experienceName = $refund->booking->experience?->title
                        ?? 'tu experiencia';

                    $formattedAmount = number_format((float) $refund->amount, 2);

                    $this->pushNotificationService->sendToUser(
                        user: $refund->booking->user,
                        title: 'Reembolso procesado',
                        body: "Tu reembolso de {$formattedAmount} {$refund->currency} para {$experienceName} fue procesado correctamente.",
                        data: [
                            'type' => 'refund_processed',
                            'booking_id' => (string) $refund->provider_booking_id,
                            'refund_id' => (string) $refund->id,
                            'transaction_id' => (string) $refund->payment_transaction_id,
                            'amount' => (string) $refund->amount,
                            'currency' => (string) $refund->currency,
                            'role' => 'customer',
                        ],
                        category: PushNotificationService::CATEGORY_PAYMENT,
                    );
                }

                return $refund;
            }

            $refund->update([
                'status' => PaymentRefund::STATUS_FAILED,

                'gateway_refund_id' => $response['AzulOrderId'] ?? null,
                'gateway_response_code' => $response['ResponseCode'] ?? null,
                'gateway_iso_code' => $response['IsoCode'] ?? null,
                'gateway_response_message' => $response['ResponseMessage'] ?? null,
                'gateway_error_description' => $response['ErrorDescription'] ?? null,

                'raw_request' => $response['raw_request'] ?? null,
                'raw_response' => $response['raw_response'] ?? $response,

                'processed_at' => now(),
            ]);

            $booking->update([
                'refund_status' => PaymentRefund::STATUS_FAILED,
            ]);

            Log::warning('Payment refund was rejected by gateway and requires manual review.', [
                'refund_id' => $refund->id,
                'booking_id' => $booking->id,
                'payment_transaction_id' => $transaction->id,
                'amount' => $refund->amount,
                'currency' => $refund->currency,
                'reason' => $reason,
                'gateway_response_code' => $response['ResponseCode'] ?? null,
                'gateway_iso_code' => $response['IsoCode'] ?? null,
                'gateway_response_message' => $response['ResponseMessage'] ?? null,
                'gateway_error_description' => $response['ErrorDescription'] ?? null,
            ]);

            return $refund;
        });
    }
}