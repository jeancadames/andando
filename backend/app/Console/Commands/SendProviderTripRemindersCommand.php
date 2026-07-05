<?php

namespace App\Console\Commands;

use App\Models\ProviderExperienceSchedule;
use App\Services\PushNotificationService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('provider:send-trip-reminders')]
#[Description('Enviar recordatorios de salidas próximas a afiliados')]
class SendProviderTripRemindersCommand extends Command
{
    public function __construct(
        private readonly PushNotificationService $pushNotificationService,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $startWindow = now()->subMinutes(5);
        $endWindow = now()->addHour();

        $schedules = ProviderExperienceSchedule::query()
            ->with([
                'provider.user',
                'experience',
                'bookings',
            ])
            ->where('status', 'available')
            ->whereNull('provider_reminder_sent_at')
            ->where('starts_at', '>', now())
            ->get();

        $sentCount = 0;

        foreach ($schedules as $schedule) {
            if (! $schedule->provider?->user || ! $schedule->starts_at) {
                continue;
            }

            $policyHours = (int) (
                $schedule->experience?->cancellation_penalty_hours
                ?: 24
            );

            $reminderHours = max($policyHours, 72);

            $reminderAt = $schedule->starts_at
                ->copy()
                ->subHours($reminderHours);

            if (! $reminderAt->betweenIncluded($startWindow, $endWindow)) {
                continue;
            }

            $experienceName = $schedule->experience?->title
                ?? 'una experiencia';

            $confirmedBookingsCount = $schedule->bookings
                ->where('status', 'confirmed')
                ->count();

            $this->pushNotificationService->sendToUser(
                user: $schedule->provider->user,
                title: 'Salida próxima',
                body: "Tu salida de {$experienceName} se acerca. Reservas confirmadas: {$confirmedBookingsCount}.",
                data: [
                    'type' => 'provider_trip_reminder',
                    'schedule_id' => (string) $schedule->id,
                    'experience_id' => (string) $schedule->provider_experience_id,
                    'starts_at' => $schedule->starts_at->toIso8601String(),
                    'confirmed_bookings_count' => (string) $confirmedBookingsCount,
                    'role' => 'provider',
                ],
                category: PushNotificationService::CATEGORY_REMINDER,
            );

            $schedule->update([
                'provider_reminder_sent_at' => now(),
            ]);

            $sentCount++;
        }

        $this->info("Recordatorios de afiliados enviados: {$sentCount}");

        return self::SUCCESS;
    }
}