<?php

namespace App\Notifications\Auth;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class WelcomeProviderNotification extends Notification
{
    use Queueable;

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Hemos recibido tu solicitud de afiliado')
            ->view('emails.auth.welcome-provider', [
                'title' => 'Solicitud recibida',
                'user' => $notifiable,
                'provider' => $notifiable->provider,
            ]);
    }
}