<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use Illuminate\Support\Facades\DB;
use Throwable;

class ProcessPaymentTransactionService
{
    public function __construct(
        private readonly PaymentGatewayManager $gatewayManager,
        private readonly ProviderPayoutService $providerPayoutService,
    ) {}

    public function process(PaymentTransaction $transaction): void
    {
        if (! $transaction->isScheduled()) {
            return;
        }

        DB::transaction(function () use ($transaction) {
            $transaction->update([
                'status' => PaymentTransaction::STATUS_PROCESSING,
            ]);
        });

        try {
            $response = $this->gatewayManager->gateway()->charge($transaction);

            DB::transaction(function () use ($transaction, $response) {
                $transaction->refresh();

                if ($response['success'] ?? false) {
                    $transaction->update([
                        'status' => PaymentTransaction::STATUS_PAID,
                        'processed_at' => now(),

                        'gateway_order_id' => $response['AzulOrderId'] ?? null,
                        'gateway_authorization_code' => $response['AuthorizationCode'] ?? null,
                        'gateway_rrn' => $response['RRN'] ?? null,
                        'gateway_response_code' => $response['ResponseCode'] ?? null,
                        'gateway_iso_code' => $response['IsoCode'] ?? null,
                        'gateway_response_message' => $response['ResponseMessage'] ?? null,
                        'gateway_error_description' => $response['ErrorDescription'] ?? null,

                        'raw_request' => $response['raw_request'] ?? null,
                        'raw_response' => $response['raw_response'] ?? $response,
                    ]);

                    $transaction->booking->update([
                        'status' => ProviderBooking::STATUS_CONFIRMED,
                        'payment_status' => PaymentTransaction::STATUS_PAID,
                        'charged_at' => now(),
                    ]);

                    $this->providerPayoutService->ensurePayoutForSchedule(
                        $transaction->schedule
                    );

                    return;
                }

                $transaction->update([
                    'status' => PaymentTransaction::STATUS_FAILED,
                    'processed_at' => now(),

                    'gateway_order_id' => $response['AzulOrderId'] ?? null,
                    'gateway_authorization_code' => $response['AuthorizationCode'] ?? null,
                    'gateway_rrn' => $response['RRN'] ?? null,
                    'gateway_response_code' => $response['ResponseCode'] ?? null,
                    'gateway_iso_code' => $response['IsoCode'] ?? null,
                    'gateway_response_message' => $response['ResponseMessage'] ?? null,
                    'gateway_error_description' => $response['ErrorDescription'] ?? null,

                    'raw_request' => $response['raw_request'] ?? null,
                    'raw_response' => $response['raw_response'] ?? $response,

                    'failure_reason' => $response['ResponseMessage']
                        ?? $response['ErrorDescription']
                        ?? 'payment_failed',
                ]);

                $transaction->booking->update([
                    'status' => ProviderBooking::STATUS_CANCELLED,
                    'payment_status' => PaymentTransaction::STATUS_FAILED,
                    'cancelled_by' => ProviderBooking::CANCELLED_BY_SYSTEM,
                    'cancellation_reason' => 'payment_failed',
                    'cancelled_at' => now(),
                ]);
            });
        } catch (Throwable $e) {
            DB::transaction(function () use ($transaction, $e) {
                $transaction->refresh();

                $transaction->update([
                    'status' => PaymentTransaction::STATUS_FAILED,
                    'processed_at' => now(),
                    'gateway_error_description' => $e->getMessage(),
                    'failure_reason' => $e->getMessage(),
                ]);

                $transaction->booking->update([
                    'status' => ProviderBooking::STATUS_CANCELLED,
                    'payment_status' => PaymentTransaction::STATUS_FAILED,
                    'cancelled_by' => ProviderBooking::CANCELLED_BY_SYSTEM,
                    'cancellation_reason' => 'payment_exception',
                    'cancelled_at' => now(),
                ]);
            });
        }
    }
}