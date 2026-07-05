<?php

namespace App\Notifications\Provider;

use App\Models\Provider;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ProviderBlockedNotification extends Notification
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
        $this->provider->loadMissing('user');

        return (new MailMessage)
            ->subject('Tu cuenta de afiliado fue suspendida')
            ->view('emails.provider.provider-blocked', [
                'title' => 'Cuenta suspendida',
                'provider' => $this->provider,
                'user' => $notifiable,
                'actionUrl' => '#',
            ]);
    }
}