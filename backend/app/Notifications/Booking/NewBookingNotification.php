<?php

namespace App\Notifications\Booking;

use App\Models\ProviderBooking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewBookingNotification extends Notification
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
            'user',
            'experience',
            'schedule',
            'provider.user',
        ]);

        return (new MailMessage)
            ->subject('Tienes una nueva reserva en AndanDO')
            ->view('emails.booking.new-booking', [
                'title' => 'Nueva reserva recibida',
                'booking' => $this->booking,
                'providerUser' => $notifiable,
                'actionUrl' => '#',
            ]);
    }
}