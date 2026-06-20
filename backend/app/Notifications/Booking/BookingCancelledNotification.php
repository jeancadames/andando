<?php

namespace App\Notifications\Booking;

use App\Models\ProviderBooking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BookingCancelledNotification extends Notification
{
    use Queueable;

    public function __construct(
        public ProviderBooking $booking,
        public string $recipientType = 'customer'
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->booking->loadMissing([
            'user',
            'experience',
            'schedule',
            'provider.user',
        ]);

        $subject = $this->recipientType === 'provider'
            ? 'Un cliente canceló una reserva en AndanDO'
            : 'Tu reserva fue cancelada correctamente';

        return (new MailMessage)
            ->subject($subject)
            ->view('emails.booking.booking-cancelled', [
                'title' => 'Reserva cancelada',
                'booking' => $this->booking,
                'recipientType' => $this->recipientType,
                'actionUrl' => '#',
            ]);
    }
}