<?php

namespace App\Notifications\Security;

use App\Models\CustomerPaymentMethod;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PaymentMethodUpdatedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public string $action,
        public ?CustomerPaymentMethod $paymentMethod = null
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Tu método de pago fue actualizado')
            ->view('emails.security.payment-method-updated', [
                'title' => 'Método de pago actualizado',
                'user' => $notifiable,
                'action' => $this->action,
                'paymentMethod' => $this->paymentMethod,
            ]);
    }
}