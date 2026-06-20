<?php

namespace App\Notifications\Auth;

use App\Models\ProviderVerificationRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ProviderRejectedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public ProviderVerificationRequest $verificationRequest
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->verificationRequest->loadMissing([
            'provider',
            'provider.businessType',
        ]);

        return (new MailMessage)
            ->subject('Necesitamos revisar tu solicitud de afiliado')
            ->view('emails.auth.provider-rejected', [
                'title' => 'Solicitud no aprobada',
                'user' => $notifiable,
                'verificationRequest' => $this->verificationRequest,
                'provider' => $this->verificationRequest->provider,
                'actionUrl' => '#',
            ]);
    }
}