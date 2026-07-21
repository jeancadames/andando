<?php

namespace App\Services\Payments;

// AndanDO Admin Payments Module

use App\Models\PaymentRefund;
use App\Models\PaymentRefundAttempt;
use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use App\Services\PushNotificationService;
use DomainException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class RetryFailedPaymentRefundService
{
    public function __construct(
        private readonly PaymentGatewayManager $gatewayManager,
        private readonly PushNotificationService $pushNotificationService,
    ) {}

    public function canRetry(PaymentRefund $refund): bool
    {
        if (! $this->hasDefinitiveFailure($refund)) {
            return false;
        }

        $refund->loadMissing('transaction.refunds');

        if (! $refund->transaction) {
            return false;
        }

        return ! $refund->transaction->refunds->contains(
            fn (PaymentRefund $other) => $other->id !== $refund->id
                && in_array($other->status, [
                    PaymentRefund::STATUS_PENDING,
                    PaymentRefund::STATUS_PROCESSING,
                    PaymentRefund::STATUS_PENDING_VERIFICATION,
                    PaymentRefund::STATUS_SUCCEEDED,
                ], true)
        );
    }

    public function retry(PaymentRefund $refund, int $adminUserId): PaymentRefund
    {
        [$lockedRefund, $attempt] = DB::transaction(function () use ($refund, $adminUserId) {
            $lockedRefund = PaymentRefund::query()
                ->with(['transaction', 'booking'])
                ->lockForUpdate()
                ->findOrFail($refund->id);

            if (! $this->hasDefinitiveFailure($lockedRefund)) {
                throw new DomainException(
                    'Esta devolución no tiene un fallo definitivo que permita reintentarla con seguridad.'
                );
            }

            $blockingRefundExists = PaymentRefund::query()
                ->where('payment_transaction_id', $lockedRefund->payment_transaction_id)
                ->where('id', '!=', $lockedRefund->id)
                ->whereIn('status', [
                    PaymentRefund::STATUS_PENDING,
                    PaymentRefund::STATUS_PROCESSING,
                    PaymentRefund::STATUS_PENDING_VERIFICATION,
                    PaymentRefund::STATUS_SUCCEEDED,
                ])
                ->exists();

            if ($blockingRefundExists) {
                throw new DomainException(
                    'Existe otra devolución activa o completada para esta transacción.'
                );
            }

            if (! $lockedRefund->transaction || ! $lockedRefund->booking) {
                throw new DomainException('La devolución perdió su transacción o reserva asociada.');
            }

            if (! in_array($lockedRefund->transaction->status, [
                PaymentTransaction::STATUS_PAID,
                PaymentTransaction::STATUS_PARTIALLY_REFUNDED,
            ], true)) {
                throw new DomainException(
                    'La transacción ya no está en un estado que permita devolver fondos.'
                );
            }

            $this->snapshotOriginalAttempt($lockedRefund);

            $nextAttempt = ((int) PaymentRefundAttempt::query()
                ->where('payment_refund_id', $lockedRefund->id)
                ->max('attempt_number')) + 1;

            $attempt = PaymentRefundAttempt::create([
                'payment_refund_id' => $lockedRefund->id,
                'attempt_number' => $nextAttempt,
                'trigger' => PaymentRefundAttempt::TRIGGER_MANUAL,
                'initiated_by_user_id' => $adminUserId,
                'status' => PaymentRefund::STATUS_PROCESSING,
                'started_at' => now(),
            ]);

            $lockedRefund->update([
                'status' => PaymentRefund::STATUS_PROCESSING,
            ]);

            $lockedRefund->booking->update([
                'refund_status' => PaymentRefund::STATUS_PROCESSING,
            ]);

            return [$lockedRefund->fresh(['transaction', 'booking']), $attempt];
        });

        try {
            $response = $this->gatewayManager->gateway()->refund($lockedRefund);
        } catch (Throwable $exception) {
            $this->markUnknown($lockedRefund, $attempt, $exception);

            return $lockedRefund->fresh();
        }

        $succeeded = (bool) ($response['success'] ?? false);

        DB::transaction(function () use ($lockedRefund, $attempt, $response, $succeeded) {
            $refund = PaymentRefund::query()->lockForUpdate()->findOrFail($lockedRefund->id);
            $transaction = PaymentTransaction::query()->lockForUpdate()->findOrFail($refund->payment_transaction_id);
            $booking = ProviderBooking::query()->lockForUpdate()->findOrFail($refund->provider_booking_id);
            $lockedAttempt = PaymentRefundAttempt::query()->lockForUpdate()->findOrFail($attempt->id);

            $gatewayData = $this->gatewayData($response);

            $lockedAttempt->update(array_merge($gatewayData, [
                'status' => $succeeded
                    ? PaymentRefund::STATUS_SUCCEEDED
                    : PaymentRefund::STATUS_FAILED,
                'completed_at' => now(),
            ]));

            $refund->update(array_merge($gatewayData, [
                'status' => $succeeded
                    ? PaymentRefund::STATUS_SUCCEEDED
                    : PaymentRefund::STATUS_FAILED,
                'gateway_refund_id' => $response['AzulOrderId'] ?? null,
                'processed_at' => now(),
            ]));

            if (! $succeeded) {
                $booking->update([
                    'refund_status' => PaymentRefund::STATUS_FAILED,
                ]);

                return;
            }

            $refundedAmount = (float) PaymentRefund::query()
                ->where('payment_transaction_id', $transaction->id)
                ->where('status', PaymentRefund::STATUS_SUCCEEDED)
                ->sum('amount');

            $retainedAmount = (float) PaymentRefund::query()
                ->where('payment_transaction_id', $transaction->id)
                ->where('status', PaymentRefund::STATUS_SUCCEEDED)
                ->sum('retained_amount');

            $isFullRefund = $refundedAmount + 0.005 >= (float) $transaction->amount;

            $transaction->update([
                'status' => $isFullRefund
                    ? PaymentTransaction::STATUS_REFUNDED
                    : PaymentTransaction::STATUS_PARTIALLY_REFUNDED,
            ]);

            $booking->update([
                'payment_status' => $isFullRefund
                    ? ProviderBooking::PAYMENT_STATUS_REFUNDED
                    : ProviderBooking::PAYMENT_STATUS_PARTIALLY_REFUNDED,
                'refund_status' => PaymentRefund::STATUS_SUCCEEDED,
                'refund_amount' => round($refundedAmount, 2),
                'refund_percentage' => (int) round(
                    ((float) $transaction->amount > 0)
                        ? ($refundedAmount / (float) $transaction->amount) * 100
                        : 0
                ),
                'administrative_fee_amount' => round($retainedAmount, 2),
                'refunded_at' => now(),
            ]);
        });

        $result = $lockedRefund->fresh(['booking.user', 'booking.experience']);

        if ($succeeded && $result?->booking?->user) {
            try {
                $experienceName = $result->booking->experience?->title ?? 'tu experiencia';
                $amount = number_format((float) $result->amount, 2);

                $this->pushNotificationService->sendToUser(
                    user: $result->booking->user,
                    title: 'Reembolso procesado',
                    body: "Tu reembolso de {$amount} {$result->currency} para {$experienceName} fue procesado correctamente.",
                    data: [
                        'type' => 'refund_processed',
                        'booking_id' => (string) $result->provider_booking_id,
                        'refund_id' => (string) $result->id,
                        'transaction_id' => (string) $result->payment_transaction_id,
                        'amount' => (string) $result->amount,
                        'currency' => (string) $result->currency,
                        'role' => 'customer',
                    ],
                    category: PushNotificationService::CATEGORY_PAYMENT,
                );
            } catch (Throwable $notificationException) {
                Log::warning('Refund succeeded but push notification failed.', [
                    'refund_id' => $result->id,
                    'exception_message' => $notificationException->getMessage(),
                ]);
            }
        }

        Log::info('Manual payment refund retry completed.', [
            'refund_id' => $lockedRefund->id,
            'attempt_id' => $attempt->id,
            'admin_user_id' => $adminUserId,
            'succeeded' => $succeeded,
        ]);

        return $result ?? $lockedRefund->fresh();
    }

    private function hasDefinitiveFailure(PaymentRefund $refund): bool
    {
        if ($refund->status !== PaymentRefund::STATUS_FAILED || (float) $refund->amount <= 0) {
            return false;
        }

        if (blank($refund->gateway_response_code) && empty($refund->raw_response)) {
            return false;
        }

        if (
            $refund->gateway !== config('payments.gateway')
            || $refund->environment !== config('payments.environment')
        ) {
            return false;
        }

        return true;
    }

    private function snapshotOriginalAttempt(PaymentRefund $refund): void
    {
        PaymentRefundAttempt::firstOrCreate(
            [
                'payment_refund_id' => $refund->id,
                'attempt_number' => 1,
            ],
            [
                'trigger' => PaymentRefundAttempt::TRIGGER_AUTOMATIC,
                'initiated_by_user_id' => null,
                'status' => $refund->status,
                'gateway_response_code' => $refund->gateway_response_code,
                'gateway_iso_code' => $refund->gateway_iso_code,
                'gateway_response_message' => $refund->gateway_response_message,
                'gateway_error_description' => $refund->gateway_error_description,
                'raw_request' => $refund->raw_request,
                'raw_response' => $refund->raw_response,
                'started_at' => $refund->created_at ?? now(),
                'completed_at' => $refund->processed_at,
            ]
        );
    }

    private function gatewayData(array $response): array
    {
        return [
            'gateway_response_code' => $response['ResponseCode'] ?? null,
            'gateway_refund_id' => $response['AzulOrderId'] ?? null,
            'gateway_iso_code' => $response['IsoCode'] ?? null,
            'gateway_response_message' => $response['ResponseMessage'] ?? null,
            'gateway_error_description' => $response['ErrorDescription'] ?? null,
            'raw_request' => $response['raw_request'] ?? null,
            'raw_response' => $response['raw_response'] ?? $response,
        ];
    }

    private function markUnknown(
        PaymentRefund $refund,
        PaymentRefundAttempt $attempt,
        Throwable $exception
    ): void {
        DB::transaction(function () use ($refund, $attempt, $exception) {
            PaymentRefundAttempt::query()->whereKey($attempt->id)->update([
                'status' => PaymentRefund::STATUS_PENDING_VERIFICATION,
                'gateway_error_description' => $exception->getMessage(),
                'completed_at' => now(),
            ]);

            PaymentRefund::query()->whereKey($refund->id)->update([
                'status' => PaymentRefund::STATUS_PENDING_VERIFICATION,
                'gateway_error_description' => $exception->getMessage(),
                'processed_at' => now(),
            ]);

            ProviderBooking::query()
                ->whereKey($refund->provider_booking_id)
                ->update([
                    'refund_status' => PaymentRefund::STATUS_PENDING_VERIFICATION,
                ]);
        });

        Log::warning('Manual refund retry has an unknown gateway result.', [
            'refund_id' => $refund->id,
            'attempt_id' => $attempt->id,
            'exception_class' => get_class($exception),
            'exception_message' => $exception->getMessage(),
        ]);
    }
}
