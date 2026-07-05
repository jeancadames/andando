<?php

namespace App\Notifications\Booking;

use App\Models\ProviderBooking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ScheduleCancelledNotification extends Notification
{
    use Queueable;

    public function __construct(
        public ProviderBooking $booking,
        public string $cancelledBy = 'provider'
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
            'paymentRefunds',
        ]);

        $subject = $this->cancelledBy === ProviderBooking::CANCELLED_BY_ADMIN
            ? 'Una salida fue cancelada por administración en AndanDO'
            : 'Una salida fue cancelada por el afiliado en AndanDO';

        return (new MailMessage)
            ->subject($subject)
            ->view('emails.booking.schedule-cancelled', [
                'title' => 'Salida cancelada',
                'booking' => $this->booking,
                'cancelledBy' => $this->cancelledBy,
                'actionUrl' => '#',
            ]);
    }
}