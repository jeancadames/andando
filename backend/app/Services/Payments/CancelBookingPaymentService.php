<?php

namespace App\Services\Payments;

use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;
use App\Models\ProviderPayout;
use Illuminate\Support\Facades\DB;
use App\Notifications\Booking\BookingCancelledNotification;
use App\Notifications\Booking\ScheduleCancelledNotification;
use App\Services\PushNotificationService;

class CancelBookingPaymentService
{
    public function __construct(
        private readonly BookingCancellationDecisionService $decisionService,
        private readonly PaymentRefundService $refundService,
        private readonly ProviderPayoutService $providerPayoutService,
        private readonly PushNotificationService $pushNotificationService,
    ) {}

    public function cancel(ProviderBooking $booking, string $reason, string $cancelledBy): void
    {
        $shouldNotify = false;
        $shouldNotifyProvider = false;

        DB::transaction(function () use ($booking, $reason, $cancelledBy, &$shouldNotify, &$shouldNotifyProvider) {
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

            if (
                $paidTransaction
                && $cancelledBy === ProviderBooking::CANCELLED_BY_CUSTOMER
                && ($decision['should_refund'] ?? false)
                && ((float) ($decision['refund_percent'] ?? 0) > 0)
            ) {
                $shouldNotifyProvider = true;
            }

            $shouldNotify = true;
        });

        if ($shouldNotify) {
            $booking->refresh();
            $booking->loadMissing([
                'user',
                'experience',
                'schedule',
                'provider.user',
            ]);

            if ($booking->user) {
                if (in_array($booking->cancelled_by, [
                    ProviderBooking::CANCELLED_BY_PROVIDER,
                    ProviderBooking::CANCELLED_BY_ADMIN,
                ], true)) {
                    $booking->user->notify(
                        new ScheduleCancelledNotification(
                            booking: $booking,
                            cancelledBy: (string) $booking->cancelled_by
                        )
                    );
                } else {
                    $booking->user->notify(
                        new BookingCancelledNotification($booking)
                    );
                }
            }
        }

        if ($shouldNotifyProvider) {
            $booking->refresh();
            $booking->loadMissing([
                'provider.user',
                'experience',
                'schedule',
                'user',
            ]);

            if ($booking->provider?->user) {
                $experienceName = $booking->experience?->title
                    ?? 'una experiencia';

                $customerName = $booking->customer_name
                    ?: $booking->user?->name
                    ?: 'Un cliente';

                $this->pushNotificationService->sendToUser(
                    user: $booking->provider->user,
                    title: 'Reserva cancelada por cliente',
                    body: "{$customerName} canceló una reserva de {$experienceName}.",
                    data: [
                        'type' => 'customer_booking_cancelled',
                        'booking_id' => (string) $booking->id,
                        'schedule_id' => (string) $booking->provider_experience_schedule_id,
                        'experience_id' => (string) $booking->provider_experience_id,
                        'role' => 'provider',
                    ],
                    category: PushNotificationService::CATEGORY_BOOKING,
                );
            }
        }
    }
}