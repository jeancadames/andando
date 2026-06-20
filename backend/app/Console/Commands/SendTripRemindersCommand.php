<?php

namespace App\Console\Commands;

use App\Models\ProviderBooking;
use App\Notifications\Booking\TripReminderNotification;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('trip:send-reminders')]
#[Description('Enviar recordatorios de viajes próximos')]
class SendTripRemindersCommand extends Command
{
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
            ->whereBetween('booking_date', [
                $startWindow,
                $endWindow,
            ])
            ->get();

        $sentCount = 0;

        foreach ($bookings as $booking) {

            if (! $booking->user) {
                continue;
            }

            $booking->user->notify(
                new TripReminderNotification($booking)
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