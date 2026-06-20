<?php

namespace App\Notifications\Booking;

use App\Models\ProviderBooking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BookingCreatedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public ProviderBooking $booking
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->booking->loadMissing([
            'experience',
            'schedule',
        ]);

        return (new MailMessage)
            ->subject('Tu reserva en AndanDO está confirmada')
            ->view('emails.booking.booking-created', [
                'title' => 'Reserva confirmada',
                'booking' => $this->booking,
                'actionUrl' => '#',
            ]);
    }
}