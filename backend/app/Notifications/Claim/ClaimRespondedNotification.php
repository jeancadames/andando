<?php

namespace App\Notifications\Claim;

use App\Models\BookingClaim;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ClaimRespondedNotification extends Notification
{
    use Queueable;

    public function __construct(public BookingClaim $claim) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->claim->loadMissing(['booking.experience', 'booking.schedule', 'provider']);

        return (new MailMessage)
            ->subject('Tu reclamo recibió una respuesta')
            ->view('emails.claim.claim-responded', [
                'title' => 'Reclamo respondido',
                'user' => $notifiable,
                'claim' => $this->claim,
                'booking' => $this->claim->booking,
                'provider' => $this->claim->provider,
                'actionUrl' => '#',
            ]);
    }
}