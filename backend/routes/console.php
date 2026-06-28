<?php

use App\Models\Conversation;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
|--------------------------------------------------------------------------
| Cerrar chats inactivos
|--------------------------------------------------------------------------
|
| Cierra conversaciones abiertas que llevan más de X horas sin interacción.
| El tiempo viene de config/chat.php:
|
| CHAT_AUTO_CLOSE_HOURS=72
|
| Uso manual:
| php artisan chat:close-inactive
|
*/
Artisan::command('chat:close-inactive', function () {
    $hours = (int) config('chat.auto_close_hours', 72);

    $closedCount = 0;

    Conversation::query()
        ->where('status', 'open')
        ->where(function ($query) use ($hours) {
            $query
                ->where(function ($innerQuery) use ($hours) {
                    $innerQuery
                        ->whereNotNull('last_message_at')
                        ->where('last_message_at', '<=', now()->subHours($hours));
                })
                ->orWhere(function ($innerQuery) use ($hours) {
                    $innerQuery
                        ->whereNull('last_message_at')
                        ->where('created_at', '<=', now()->subHours($hours));
                });
        })
        ->chunkById(100, function ($conversations) use (&$closedCount) {
            foreach ($conversations as $conversation) {
                $conversation->update([
                    'status' => 'closed',
                    'closed_reason' => 'inactive',
                    'closed_at' => now(),
                ]);

                $closedCount++;
            }
        });

    $this->info("Chats cerrados por inactividad: {$closedCount}");
})->purpose('Cerrar conversaciones inactivas después del tiempo configurado.');

Schedule::command('chat:close-inactive')->hourly();

Schedule::command('trip:send-reminders')->hourly();

Schedule::command('payments:process-scheduled-charges')->hourly();

Schedule::command('payments:release-provider-payouts')->hourly();