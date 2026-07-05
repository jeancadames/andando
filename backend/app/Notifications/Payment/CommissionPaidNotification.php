<?php

namespace App\Notifications\Payment;

use App\Models\ProviderPayout;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class CommissionPaidNotification extends Notification
{
    use Queueable;

    public function __construct(
        public ProviderPayout $payout
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->payout->loadMissing([
            'provider.user',
        ]);

        return (new MailMessage)
            ->subject('Pago procesado en AndanDO')
            ->view('emails.payment.commission-paid', [
                'title' => 'Pago procesado',
                'payout' => $this->payout,
                'provider' => $this->payout->provider,
                'amount' => number_format((float) $this->payout->amount, 2),
            ]);
    }
}