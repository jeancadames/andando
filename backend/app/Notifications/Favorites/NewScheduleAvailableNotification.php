<?php

namespace App\Notifications\Favorites;

use App\Models\ProviderExperienceSchedule;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewScheduleAvailableNotification extends Notification
{
    use Queueable;

    public function __construct(
        public ProviderExperienceSchedule $schedule
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->schedule->loadMissing(['experience']);

        return (new MailMessage)
            ->subject('Nueva fecha disponible para una experiencia favorita')
            ->view('emails.favorites.new-schedule-available', [
                'title' => 'Nueva fecha disponible',
                'user' => $notifiable,
                'schedule' => $this->schedule,
                'experience' => $this->schedule->experience,
                'actionUrl' => '#',
            ]);
    }
}