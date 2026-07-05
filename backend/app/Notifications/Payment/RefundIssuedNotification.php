<?php

namespace App\Notifications\Payment;

use App\Models\PaymentRefund;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class RefundIssuedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public PaymentRefund $refund
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->refund->loadMissing([
            'booking.user',
            'booking.experience',
            'booking.schedule',
        ]);

        $booking = $this->refund->booking;

        return (new MailMessage)
            ->subject('Reembolso procesado en AndanDO')
            ->view('emails.payment.refund-issued', [
                'title' => 'Reembolso procesado',
                'refund' => $this->refund,
                'booking' => $booking,
                'amount' => number_format((float) $this->refund->amount, 2),
            ]);
    }
}