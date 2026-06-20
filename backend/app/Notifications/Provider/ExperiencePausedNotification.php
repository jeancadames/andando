<?php

namespace App\Notifications\Provider;

use App\Models\ProviderExperience;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ExperiencePausedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public ProviderExperience $experience
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->experience->loadMissing(['provider']);

        return (new MailMessage)
            ->subject('Una experiencia fue pausada por administración')
            ->view('emails.provider.experience-paused', [
                'title' => 'Experiencia pausada',
                'user' => $notifiable,
                'experience' => $this->experience,
                'provider' => $this->experience->provider,
                'actionUrl' => '#',
            ]);
    }
}