<?php

namespace Database\Seeders;

use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use Illuminate\Database\Seeder;

class ProviderExperienceScheduleSeeder extends Seeder
{
    public function run(): void
    {
        $experiences = ProviderExperience::query()
            ->where('status', 'published')
            ->where('is_active', true)
            ->get();

        foreach ($experiences as $experience) {
            $dates = [
                now()->addDays(2)->setTime(8, 0),
                now()->addDays(4)->setTime(8, 0),
                now()->addDays(6)->setTime(9, 0),
                now()->addDays(8)->setTime(8, 30),
            ];

            foreach ($dates as $index => $startsAt) {
                ProviderExperienceSchedule::updateOrCreate(
                    [
                        'provider_experience_id' => $experience->id,
                        'starts_at' => $startsAt,
                    ],
                    [
                        'provider_id' => $experience->provider_id,
                        'series_id' => null,
                        'ends_at' => (clone $startsAt)->addHours(4),
                        'timezone' => 'America/Santo_Domingo',
                        'capacity' => max(1, (int) $experience->capacity),
                        'price' => $experience->price,
                        'currency' => $experience->currency ?? 'DOP',
                        'status' => 'active',
                        'notes' => 'Horario demo #' . ($index + 1),
                        'cancellation_reason' => null,
                    ]
                );
            }
        }
    }
}