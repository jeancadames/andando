<?php

namespace App\Jobs;

use App\Services\Notifications\FirebasePushNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SendPushNotificationJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public int $userId,
        public string $title,
        public string $body,
        public array $data = []
    ) {
        //
    }

    public function handle(FirebasePushNotificationService $pushService): void
    {
        $pushService->sendToUser(
            user: $this->userId,
            title: $this->title,
            body: $this->body,
            data: $this->data
        );
    }
}