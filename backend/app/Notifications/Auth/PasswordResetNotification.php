<?php

namespace App\Notifications\Auth;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class PasswordResetNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly string $token,
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $frontendUrl = rtrim((string) config('app.frontend_url', config('app.url')), '/');

        $resetUrl = URL::query($frontendUrl . '/#/reset-password', [
            'token' => $this->token,
            'email' => $notifiable->getEmailForPasswordReset(),
        ]);

        return (new MailMessage)
            ->subject('Recupera tu contraseña de AndanDO')
            ->view('emails.auth.password-reset', [
                'title' => 'Recuperar contraseña',
                'user' => $notifiable,
                'resetUrl' => $resetUrl,
            ]);
    }
}