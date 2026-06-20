<?php

namespace App\Notifications\Admin;

use App\Models\BookingClaim;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewClaimForReviewNotification extends Notification
{
    use Queueable;

    public function __construct(
        public BookingClaim $claim
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->claim->loadMissing([
            'user',
            'provider',
            'booking.experience',
            'booking.schedule',
        ]);

        return (new MailMessage)
            ->subject('Nuevo reclamo pendiente de revisión')
            ->view('emails.admin.new-claim-review', [
                'title' => 'Nuevo reclamo pendiente',
                'claim' => $this->claim,
                'booking' => $this->claim->booking,
                'customer' => $this->claim->user,
                'provider' => $this->claim->provider,
            ]);
    }
}