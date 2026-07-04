<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use Illuminate\Support\Facades\DB;
use Throwable;

class ReconcilePendingPaymentTransactionService
{
    public function __construct(
        private readonly PaymentGatewayManager $gatewayManager,
        private readonly ProviderPayoutService $providerPayoutService,
    ) {}

    public function reconcile(PaymentTransaction $transaction): void
    {
        if ($transaction->status !== PaymentTransaction::STATUS_PENDING_VERIFICATION) {
            return;
        }

        try {
            $response = $this->gatewayManager->gateway()->verify($transaction);
        } catch (Throwable $e) {
            $transaction->update([
                'gateway_error_description' => 'verification_failed_retry_required',
                'failure_reason' => 'pending_verification_retry_required',
            ]);

            return;
        }

        DB::transaction(function () use ($transaction, $response) {
            $transaction->refresh();

            if (($response['Found'] ?? false) === true
                && ($response['ResponseCode'] ?? null) === 'ISO8583'
                && ($response['IsoCode'] ?? null) === '00'
            ) {
                $transaction->update([
                    'status' => PaymentTransaction::STATUS_PAID,
                    'processed_at' => now(),

                    'gateway_order_id' => $response['AzulOrderId'] ?? null,
                    'gateway_authorization_code' => $response['AuthorizationCode'] ?? null,
                    'gateway_rrn' => $response['RRN'] ?? null,
                    'gateway_response_code' => $response['ResponseCode'] ?? null,
                    'gateway_iso_code' => $response['IsoCode'] ?? null,
                    'gateway_response_message' => $response['ResponseMessage'] ?? null,
                    'gateway_error_description' => null,

                    'raw_response' => $response,
                    'failure_reason' => null,
                ]);

                $transaction->booking->update([
                    'status' => ProviderBooking::STATUS_CONFIRMED,
                    'payment_status' => ProviderBooking::PAYMENT_STATUS_PAID,
                    'charged_at' => now(),
                ]);

                $this->providerPayoutService->ensurePayoutForSchedule(
                    $transaction->schedule
                );

                return;
            }

            if (($response['Found'] ?? false) === false) {
                $transaction->update([
                    'gateway_response_code' => $response['ResponseCode'] ?? null,
                    'gateway_iso_code' => $response['IsoCode'] ?? null,
                    'gateway_response_message' => $response['ResponseMessage'] ?? null,
                    'gateway_error_description' => 'payment_not_found_during_verification',
                    'raw_response' => $response,
                    'failure_reason' => 'still_pending_verification',
                ]);

                return;
            }

            $transaction->update([
                'gateway_response_code' => $response['ResponseCode'] ?? null,
                'gateway_iso_code' => $response['IsoCode'] ?? null,
                'gateway_response_message' => $response['ResponseMessage'] ?? null,
                'gateway_error_description' => $response['ErrorDescription'] ?? 'verification_not_approved',
                'raw_response' => $response,
                'failure_reason' => 'verification_not_approved',
            ]);
        });
    }
}