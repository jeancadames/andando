<?php

namespace App\Notifications\Auth;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class WelcomeCustomerNotification extends Notification
{
    use Queueable;

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('¡Bienvenido a AndanDO!')
            ->view('emails.auth.welcome-customer', [
                'title' => 'Bienvenido a AndanDO',
                'user' => $notifiable,
            ]);
    }
}