<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use App\Notifications\Payment\PaymentConfirmedNotification;
use App\Notifications\Payment\PaymentFailedNotification;
use App\Services\PushNotificationService;
use Illuminate\Support\Facades\DB;
use Throwable;

class ProcessPaymentTransactionService
{
    public function __construct(
        private readonly PaymentGatewayManager $gatewayManager,
        private readonly ProviderPayoutService $providerPayoutService,
        private readonly PushNotificationService $pushNotificationService,
    ) {}

    public function process(PaymentTransaction $transaction): void
    {
        $paymentConfirmed = false;
        $paymentFailed = false;

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

            DB::transaction(function () use (
                $transaction,
                $response,
                &$paymentConfirmed,
                &$paymentFailed
            ) {
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

                    $paymentConfirmed = true;

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

                $paymentFailed = true;
            });
        } catch (Throwable $e) {
            DB::transaction(function () use ($transaction) {
                $transaction->refresh();

                $transaction->update([
                    'status' => PaymentTransaction::STATUS_PENDING_VERIFICATION,
                    'gateway_error_description' => 'payment_status_unknown_after_gateway_exception',
                    'failure_reason' => 'pending_verification_required',
                ]);

                $transaction->booking->update([
                    'payment_status' => ProviderBooking::PAYMENT_STATUS_PENDING_VERIFICATION,
                ]);
            });

            return;
        }

        $transaction->refresh();
        $transaction->loadMissing([
            'booking.user',
            'booking.provider.user',
            'booking.experience',
            'schedule',
        ]);

        if ($paymentConfirmed && $transaction->booking?->user) {
            $transaction->booking->user->notify(
                new PaymentConfirmedNotification($transaction)
            );

            $experienceName = $transaction->booking->experience?->title
                ?? 'tu experiencia';

            $this->pushNotificationService->sendToUser(
                user: $transaction->booking->user,
                title: 'Reserva confirmada',
                body: "Tu reserva para {$experienceName} fue confirmada correctamente.",
                data: [
                    'type' => 'booking_confirmed',
                    'booking_id' => (string) $transaction->booking->id,
                    'transaction_id' => (string) $transaction->id,
                    'schedule_id' => (string) $transaction->provider_experience_schedule_id,
                    'role' => 'customer',
                ],
                category: PushNotificationService::CATEGORY_BOOKING,
            );
        }

        if ($paymentConfirmed && $transaction->booking?->provider?->user) {
            $experienceName = $transaction->booking->experience?->title
                ?? 'una experiencia';

            $customerName = $transaction->booking->customer_name
                ?: $transaction->booking->user?->name
                ?: 'Un cliente';

            $this->pushNotificationService->sendToUser(
                user: $transaction->booking->provider->user,
                title: 'Nueva reserva recibida',
                body: "{$customerName} reservó {$experienceName}.",
                data: [
                    'type' => 'provider_booking_received',
                    'booking_id' => (string) $transaction->booking->id,
                    'transaction_id' => (string) $transaction->id,
                    'schedule_id' => (string) $transaction->provider_experience_schedule_id,
                    'role' => 'provider',
                ],
                category: PushNotificationService::CATEGORY_BOOKING,
            );
        }

        if ($paymentFailed && $transaction->booking?->user) {
            $transaction->booking->user->notify(
                new PaymentFailedNotification($transaction)
            );
        }
    }
}