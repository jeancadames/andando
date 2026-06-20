<?php

namespace App\Services\Notifications;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Exception\MessagingException;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Throwable;

class FirebasePushNotificationService
{
    public function sendToUser(
        User|int $user,
        string $title,
        string $body,
        array $data = []
    ): array {
        $userId = $user instanceof User ? $user->id : $user;

        $tokens = DeviceToken::query()
            ->where('user_id', $userId)
            ->pluck('token')
            ->filter()
            ->unique()
            ->values();

        if ($tokens->isEmpty()) {
            return [
                'success' => false,
                'sent' => 0,
                'failed' => 0,
                'message' => 'User has no device tokens.',
            ];
        }

        $sent = 0;
        $failed = 0;
        $invalidTokens = [];

        foreach ($tokens as $token) {
            try {
                $message = CloudMessage::new()
                    ->toToken($token)
                    ->withNotification(Notification::create($title, $body))
                    ->withData($this->normalizeData($data));

                app('firebase.messaging')->send($message);

                $sent++;
            } catch (NotFound $exception) {
                $failed++;
                $invalidTokens[] = $token;

                Log::warning('FCM token not found.', [
                    'user_id' => $userId,
                    'error' => $exception->getMessage(),
                ]);
            } catch (MessagingException $exception) {
                $failed++;

                Log::warning('FCM messaging error.', [
                    'user_id' => $userId,
                    'error' => $exception->getMessage(),
                ]);
            } catch (Throwable $exception) {
                $failed++;

                Log::error('Unexpected FCM error.', [
                    'user_id' => $userId,
                    'error' => $exception->getMessage(),
                ]);
            }
        }

        if (! empty($invalidTokens)) {
            DeviceToken::query()
                ->whereIn('token', $invalidTokens)
                ->delete();
        }

        return [
            'success' => $sent > 0,
            'sent' => $sent,
            'failed' => $failed,
            'invalid_tokens_deleted' => count($invalidTokens),
        ];
    }

    private function normalizeData(array $data): array
    {
        return collect($data)
            ->mapWithKeys(function ($value, $key) {
                if (is_bool($value)) {
                    $value = $value ? 'true' : 'false';
                }

                if (is_null($value)) {
                    $value = '';
                }

                if (is_int($value) || is_float($value)) {
                    $value = (string) $value;
                }

                if (is_array($value) || is_object($value)) {
                    $value = json_encode($value);
                }

                return [(string) $key => (string) $value];
            })
            ->toArray();
    }
}