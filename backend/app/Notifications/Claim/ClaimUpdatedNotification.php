<?php

namespace App\Notifications\Claim;

use App\Models\BookingClaim;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ClaimUpdatedNotification extends Notification
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

        $subject = $this->claim->status === 'resolved'
            ? 'Tu reclamo fue resuelto'
            : 'Tu reclamo fue actualizado';

        return (new MailMessage)
            ->subject($subject)
            ->view('emails.claim.claim-updated', [
                'title' => 'Reclamo actualizado',
                'user' => $notifiable,
                'claim' => $this->claim,
                'booking' => $this->claim->booking,
                'actionUrl' => '#',
            ]);
    }
}