<?php

namespace App\Services;

use App\Jobs\SendPushNotificationJob;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    public const CATEGORY_BOOKING = 'booking';
    public const CATEGORY_MESSAGE = 'message';
    public const CATEGORY_PAYMENT = 'payment';
    public const CATEGORY_CLAIM = 'claim';
    public const CATEGORY_PAYOUT = 'payout';
    public const CATEGORY_REMINDER = 'reminder';

    public function sendToUser(
        User $user,
        string $title,
        string $body,
        array $data = [],
        ?string $category = null,
    ): void {
        if (! $user->id) {
            return;
        }

        if (! $this->userAllowsPush($user, $category)) {
            return;
        }

        try {
            SendPushNotificationJob::dispatch(
                userId: $user->id,
                title: $title,
                body: $body,
                data: $data
            );
        } catch (\Throwable $exception) {
            Log::error('Error dispatching push notification job.', [
                'user_id' => $user->id,
                'title' => $title,
                'category' => $category,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    private function userAllowsPush(User $user, ?string $category): bool
    {
        $preference = $user->notificationPreference;

        if (! $preference) {
            return true;
        }

        if (! $preference->push_enabled) {
            return false;
        }

        return match ($category) {
            self::CATEGORY_BOOKING => $preference->booking_notifications_enabled,
            self::CATEGORY_MESSAGE => $preference->message_notifications_enabled,
            self::CATEGORY_PAYMENT => $preference->payment_notifications_enabled,
            self::CATEGORY_CLAIM => $preference->claim_notifications_enabled,
            self::CATEGORY_PAYOUT => $preference->payout_notifications_enabled,
            self::CATEGORY_REMINDER => $preference->reminder_notifications_enabled,
            default => true,
        };
    }
}