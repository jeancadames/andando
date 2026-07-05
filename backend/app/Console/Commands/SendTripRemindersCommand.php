<?php

namespace App\Console\Commands;

use App\Models\ProviderBooking;
use App\Notifications\Booking\TripReminderNotification;
use App\Services\PushNotificationService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('trip:send-reminders')]
#[Description('Enviar recordatorios de viajes próximos')]
class SendTripRemindersCommand extends Command
{
    public function __construct(
        private readonly PushNotificationService $pushNotificationService,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $startWindow = now()->addHours(23);
        $endWindow = now()->addHours(25);

        $bookings = ProviderBooking::query()
            ->with([
                'user',
                'experience',
                'schedule',
            ])
            ->whereIn('status', ['pending', 'confirmed'])
            ->whereNull('trip_reminder_sent_at')
            ->where(function ($query) use ($startWindow, $endWindow) {
                $query
                    ->whereBetween('booking_date', [
                        $startWindow,
                        $endWindow,
                    ])
                    ->orWhereHas('schedule', function ($scheduleQuery) use ($startWindow, $endWindow) {
                        $scheduleQuery->whereBetween('starts_at', [
                            $startWindow,
                            $endWindow,
                        ]);
                    });
            })
            ->get();

        $sentCount = 0;

        foreach ($bookings as $booking) {
            if (! $booking->user) {
                continue;
            }

            $startsAt = $booking->schedule?->starts_at
                ?? $booking->booking_date;

            if (! $startsAt || ! $startsAt->betweenIncluded($startWindow, $endWindow)) {
                continue;
            }

            $booking->user->notify(
                new TripReminderNotification($booking)
            );

            $experienceName = $booking->experience?->title
                ?? 'tu experiencia';

            $this->pushNotificationService->sendToUser(
                user: $booking->user,
                title: 'Tu salida es mañana',
                body: "Recuerda que tu salida para {$experienceName} es en aproximadamente 24 horas.",
                data: [
                    'type' => 'trip_reminder_24h',
                    'booking_id' => (string) $booking->id,
                    'schedule_id' => (string) $booking->provider_experience_schedule_id,
                    'starts_at' => $startsAt->toIso8601String(),
                    'role' => 'customer',
                ],
                category: PushNotificationService::CATEGORY_REMINDER,
            );

            $booking->update([
                'trip_reminder_sent_at' => now(),
            ]);

            $sentCount++;
        }

        $this->info(
            "Recordatorios enviados: {$sentCount}"
        );

        return self::SUCCESS;
    }
}