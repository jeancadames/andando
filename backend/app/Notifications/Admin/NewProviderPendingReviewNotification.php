<?php

namespace App\Notifications\Admin;

use App\Models\Provider;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewProviderPendingReviewNotification extends Notification
{
    use Queueable;

    public function __construct(
        public Provider $provider
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->provider->loadMissing([
            'user',
            'businessType',
        ]);

        return (new MailMessage)
            ->subject('Nuevo afiliado pendiente de revisión')
            ->view('emails.admin.new-provider-pending-review', [
                'provider' => $this->provider,
                'user' => $this->provider->user,
            ]);
    }
}