<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use App\Models\ProviderExperienceScheduleSeries;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ProviderExperienceScheduleController extends Controller
{
    private const MAX_GENERATED_DATES = 370;

    public function index(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $schedules = $experience->schedules()
            ->withSum([
                'bookings as booked' => function ($query) {
                    $query->whereIn('status', ['pending', 'confirmed']);
                },
            ], 'guests_count')
            ->orderBy('starts_at')
            ->get()
            ->map(fn ($schedule) => $this->formatSchedule($schedule));

        return response()->json([
            'experience' => [
                'id' => $experience->id,
                'title' => $experience->title,
                'capacity' => $experience->capacity,
                'price' => (float) $experience->price,
                'currency' => $experience->currency,
            ],
            'data' => $schedules,
        ]);
    }

    /**
     * Crea fechas programadas.
     *
     * schedule_type=single:
     * - date
     * - time
     *
     * schedule_type=multiple:
     * - start_date
     * - end_date
     * - time
     * - frequency: daily, weekly, custom
     * - days_of_week: requerido si frequency=custom
     *
     * Capacidad y precio se toman desde provider_experiences.
     */
    public function store(Request $request, ProviderExperience $experience): JsonResponse
    {
        $this->authorizeProvider($request, $experience);

        $scheduleType = $request->input('schedule_type', 'single');

        if ($scheduleType === 'multiple') {
            return $this->storeMultiple($request, $experience);
        }

        return $this->storeSingle($request, $experience);
    }

    private function storeSingle(Request $request, ProviderExperience $experience): JsonResponse
    {
        $validated = $request->validate([
            'date' => ['required_without:starts_at', 'date', 'after_or_equal:today'],
            'time' => ['required_without:starts_at', 'date_format:H:i'],
            'starts_at' => ['nullable', 'date', 'after_or_equal:now'],
            'timezone' => ['nullable', 'string', 'max:80'],
            'notes' => ['nullable', 'string'],
        ]);

        $timezone = $validated['timezone'] ?? 'America/Santo_Domingo';

        $startsAt = isset($validated['starts_at'])
            ? CarbonImmutable::parse($validated['starts_at'], $timezone)
            : CarbonImmutable::parse(
                "{$validated['date']} {$validated['time']}",
                $timezone
            );

        if ($this->scheduleExists($experience, $startsAt)) {
            return response()->json([
                'message' => 'Ya existe una fecha programada para esta experiencia en esa fecha y hora.',
            ], 422);
        }

        $schedule = ProviderExperienceSchedule::create([
            'provider_id' => $experience->provider_id,
            'provider_experience_id' => $experience->id,
            'series_id' => null,
            'starts_at' => $startsAt,
            'ends_at' => null,
            'timezone' => $timezone,
            'capacity' => $experience->capacity,
            'price' => $experience->price,
            'currency' => $experience->currency ?? 'DOP',
            'status' => 'active',
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'message' => 'Fecha programada creada correctamente.',
            'created_count' => 1,
            'skipped_count' => 0,
            'data' => $this->formatSchedule($schedule),
        ], 201);
    }

    private function storeMultiple(Request $request, ProviderExperience $experience): JsonResponse
    {
        $validated = $request->validate([
            'start_date' => ['required', 'date', 'after_or_equal:today'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
            'time' => ['required', 'date_format:H:i'],
            'timezone' => ['nullable', 'string', 'max:80'],
            'frequency' => ['required', Rule::in(['daily', 'weekly', 'custom'])],
            'days_of_week' => ['nullable', 'array'],
            'days_of_week.*' => [
                'string',
                Rule::in([
                    'monday',
                    'tuesday',
                    'wednesday',
                    'thursday',
                    'friday',
                    'saturday',
                    'sunday',
                ]),
            ],
        ]);

        if (
            $validated['frequency'] === 'custom'
            && empty($validated['days_of_week'])
        ) {
            return response()->json([
                'message' => 'Debes seleccionar al menos un día de la semana.',
            ], 422);
        }

        $timezone = $validated['timezone'] ?? 'America/Santo_Domingo';

        $starts = $this->generateStartDates(
            startDate: $validated['start_date'],
            endDate: $validated['end_date'],
            time: $validated['time'],
            timezone: $timezone,
            frequency: $validated['frequency'],
            daysOfWeek: $validated['days_of_week'] ?? [],
        );

        if (count($starts) > self::MAX_GENERATED_DATES) {
            return response()->json([
                'message' => 'La programación genera demasiadas fechas. Reduce el rango de fechas.',
                'max_allowed' => self::MAX_GENERATED_DATES,
            ], 422);
        }

        if (count($starts) === 0) {
            return response()->json([
                'message' => 'No se generó ninguna fecha con la configuración seleccionada.',
            ], 422);
        }

        return DB::transaction(function () use ($experience, $validated, $timezone, $starts) {
            $series = ProviderExperienceScheduleSeries::create([
                'provider_id' => $experience->provider_id,
                'provider_experience_id' => $experience->id,
                'starts_on' => $validated['start_date'],
                'ends_on' => $validated['end_date'],
                'departure_time' => $validated['time'],
                'timezone' => $timezone,
                'frequency' => $validated['frequency'],
                'days_of_week' => $validated['days_of_week'] ?? null,
                'status' => 'active',
            ]);

            $created = [];
            $skipped = 0;

            foreach ($starts as $startsAt) {
                if ($this->scheduleExists($experience, $startsAt)) {
                    $skipped++;
                    continue;
                }

                $created[] = ProviderExperienceSchedule::create([
                    'provider_id' => $experience->provider_id,
                    'provider_experience_id' => $experience->id,
                    'series_id' => $series->id,
                    'starts_at' => $startsAt,
                    'ends_at' => null,
                    'timezone' => $timezone,
                    'capacity' => $experience->capacity,
                    'price' => $experience->price,
                    'currency' => $experience->currency ?? 'DOP',
                    'status' => 'active',
                ]);
            }

            return response()->json([
                'message' => 'Fechas programadas creadas correctamente.',
                'series_id' => $series->id,
                'created_count' => count($created),
                'skipped_count' => $skipped,
                'data' => collect($created)
                    ->map(fn ($schedule) => $this->formatSchedule($schedule))
                    ->values(),
            ], 201);
        });
    }

    public function update(
        Request $request,
        ProviderExperience $experience,
        ProviderExperienceSchedule $schedule
    ): JsonResponse {
        $this->authorizeProvider($request, $experience);
        $this->authorizeSchedule($experience, $schedule);

        $booked = $this->bookedSeats($schedule);

        if ($booked > 0) {
            return response()->json([
                'message' => 'No puedes editar una fecha que ya tiene reservas.',
            ], 422);
        }

        $validated = $request->validate([
            'starts_at' => ['required', 'date', 'after_or_equal:now'],
            'status' => ['nullable', 'in:active,paused,cancelled'],
            'notes' => ['nullable', 'string'],
        ]);

        $schedule->update([
            'starts_at' => $validated['starts_at'],
            'status' => $validated['status'] ?? $schedule->status,
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'message' => 'Fecha programada actualizada correctamente.',
            'data' => $this->formatSchedule($schedule->fresh()),
        ]);
    }

    public function destroy(
        Request $request,
        ProviderExperience $experience,
        ProviderExperienceSchedule $schedule
    ): JsonResponse {
        $this->authorizeProvider($request, $experience);
        $this->authorizeSchedule($experience, $schedule);

        if ($this->bookedSeats($schedule) > 0) {
            return response()->json([
                'message' => 'No puedes eliminar una fecha que ya tiene reservas.',
            ], 422);
        }

        $schedule->delete();

        return response()->json([
            'message' => 'Fecha programada eliminada correctamente.',
        ]);
    }

    private function generateStartDates(
        string $startDate,
        string $endDate,
        string $time,
        string $timezone,
        string $frequency,
        array $daysOfWeek
    ): array {
        $start = CarbonImmutable::parse($startDate, $timezone)->startOfDay();
        $end = CarbonImmutable::parse($endDate, $timezone)->startOfDay();

        $starts = [];

        if ($frequency === 'weekly') {
            $current = $start;

            while ($current->lessThanOrEqualTo($end)) {
                $starts[] = CarbonImmutable::parse(
                    $current->format('Y-m-d') . " {$time}",
                    $timezone
                );

                $current = $current->addWeek();
            }

            return $starts;
        }

        $current = $start;

        while ($current->lessThanOrEqualTo($end)) {
            $englishDay = strtolower($current->englishDayOfWeek);

            if (
                $frequency === 'daily'
                || (
                    $frequency === 'custom'
                    && in_array($englishDay, $daysOfWeek, true)
                )
            ) {
                $starts[] = CarbonImmutable::parse(
                    $current->format('Y-m-d') . " {$time}",
                    $timezone
                );
            }

            $current = $current->addDay();
        }

        return $starts;
    }

    private function scheduleExists(
        ProviderExperience $experience,
        CarbonImmutable $startsAt
    ): bool {
        return ProviderExperienceSchedule::query()
            ->where('provider_experience_id', $experience->id)
            ->where('starts_at', $startsAt->format('Y-m-d H:i:s'))
            ->exists();
    }

    private function authorizeProvider(Request $request, ProviderExperience $experience): void
    {
        if ((int) $experience->provider_id !== (int) $request->user()->id) {
            abort(403, 'No tienes permiso para esta experiencia.');
        }
    }

    private function authorizeSchedule(
        ProviderExperience $experience,
        ProviderExperienceSchedule $schedule
    ): void {
        if ((int) $schedule->provider_experience_id !== (int) $experience->id) {
            abort(404, 'La fecha no pertenece a esta experiencia.');
        }
    }

    private function bookedSeats(ProviderExperienceSchedule $schedule): int
    {
        return (int) $schedule->bookings()
            ->whereIn('status', ['pending', 'confirmed'])
            ->sum('guests_count');
    }

    private function formatSchedule(ProviderExperienceSchedule $schedule): array
    {
        $booked = (int) ($schedule->booked ?? $this->bookedSeats($schedule));
        $available = max($schedule->capacity - $booked, 0);

        return [
            'id' => $schedule->id,
            'provider_experience_id' => $schedule->provider_experience_id,
            'series_id' => $schedule->series_id,
            'starts_at' => optional($schedule->starts_at)->toISOString(),
            'ends_at' => optional($schedule->ends_at)->toISOString(),
            'timezone' => $schedule->timezone,
            'capacity' => $schedule->capacity,
            'booked' => $booked,
            'available' => $available,
            'price' => (float) $schedule->price,
            'currency' => $schedule->currency,
            'status' => $schedule->status,
            'notes' => $schedule->notes,
            'estimated_revenue' => $booked * (float) $schedule->price,
        ];
    }
}