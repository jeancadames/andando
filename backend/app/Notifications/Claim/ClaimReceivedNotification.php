<?php

namespace App\Notifications\Claim;

use App\Models\BookingClaim;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ClaimReceivedNotification extends Notification
{
    use Queueable;

    public function __construct(public BookingClaim $claim) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->claim->loadMissing(['booking.experience', 'booking.schedule']);

        return (new MailMessage)
            ->subject('Hemos recibido tu reclamo')
            ->view('emails.claim.claim-received', [
                'title' => 'Reclamo recibido',
                'user' => $notifiable,
                'claim' => $this->claim,
                'booking' => $this->claim->booking,
                'actionUrl' => '#',
            ]);
    }
}