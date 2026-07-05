<?php

namespace App\Notifications\Payment;

use App\Models\PaymentTransaction;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PaymentFailedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public PaymentTransaction $transaction
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->transaction->loadMissing([
            'booking.user',
            'booking.experience',
            'booking.schedule',
        ]);

        $booking = $this->transaction->booking;

        return (new MailMessage)
            ->subject('No pudimos procesar tu pago en AndanDO')
            ->view('emails.payment.payment-failed', [
                'title' => 'Pago fallido',
                'transaction' => $this->transaction,
                'booking' => $booking,
                'amount' => number_format((float) $this->transaction->amount, 2),
            ]);
    }
}