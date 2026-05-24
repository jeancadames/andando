<?php

namespace App\Services\Provider;

use App\Models\CustomerFavoriteExperience;
use App\Models\Provider;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderExperienceSchedule;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class ProviderAnalyticsService
{
    public function __construct(
        private readonly ProviderInsightService $insightService,
    ) {
    }

    /**
     * Genera el análisis estadístico completo del proveedor.
     *
     * Todo es solo lectura.
     */
    public function getAnalytics(User $user, array $filters = []): array
    {
        $provider = $user->provider;

        $period = $filters['period'] ?? '30d';
        $experienceId = $filters['experience_id'] ?? null;

        [$startDate, $endDate] = $this->resolveDateRange($filters, $period);

        $experienceIds = $this->getProviderExperienceIds(
            provider: $provider,
            experienceId: $experienceId,
        );

        $confirmedBookings = $this->getConfirmedBookings(
            provider: $provider,
            experienceIds: $experienceIds,
            startDate: $startDate,
            endDate: $endDate,
        );

        $cancelledBookings = $this->getCancelledBookings(
            provider: $provider,
            experienceIds: $experienceIds,
            startDate: $startDate,
            endDate: $endDate,
        );

        $summary = $this->buildSummary(
            provider: $provider,
            experienceIds: $experienceIds,
            confirmedBookings: $confirmedBookings,
            cancelledBookings: $cancelledBookings,
            startDate: $startDate,
            endDate: $endDate,
            experienceId: $experienceId,
        );

        $analytics = [
            'message' => 'Análisis del proveedor obtenido correctamente.',
            'filters' => [
                'period' => $period,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'experience_id' => $experienceId ? (int) $experienceId : null,
            ],
            'provider' => [
                'id' => $provider->id,
                'business_name' => $provider->business_name,
                'status' => $provider->status,
            ],
            'summary' => $summary,
            'audience' => $this->buildAudience($confirmedBookings),
            'conversion' => $this->buildConversion(
                experienceIds: $experienceIds,
                confirmedBookings: $confirmedBookings,
                startDate: $startDate,
                endDate: $endDate,
            ),
            'schedules' => [
                'upcoming' => $this->buildUpcomingSchedules(
                    provider: $provider,
                    experienceIds: $experienceIds,
                ),
                'occupancy_by_weekday' => $this->buildOccupancyByWeekday(
                    provider: $provider,
                    experienceIds: $experienceIds,
                    startDate: $startDate,
                    endDate: $endDate,
                ),
                'booking_heatmap' => $this->buildBookingHeatmap($confirmedBookings),
            ],
            'demand' => [
                'booking_lead_time' => $this->buildBookingLeadTime($confirmedBookings),
            ],
            'experiences' => $this->buildExperiencePerformance(
                provider: $provider,
                experienceIds: $experienceIds,
                confirmedBookings: $confirmedBookings,
                startDate: $startDate,
                endDate: $endDate,
            ),
            'loyalty' => $this->buildLoyalty(
                provider: $provider,
                confirmedBookings: $confirmedBookings,
                startDate: $startDate,
            ),
            'available_experiences' => $this->buildAvailableExperiences($provider),
            'warnings' => [
                'low_data' => $confirmedBookings->count() < 5,
                'message' => $confirmedBookings->count() < 5
                    ? 'Hay pocos datos todavía. Las métricas pueden cambiar mucho cuando entren más reservas confirmadas.'
                    : null,
            ],
        ];

        $analytics['insights'] = $this->insightService->generate($analytics);

        return $analytics;
    }

    private function getProviderExperienceIds(
        Provider $provider,
        mixed $experienceId,
    ): Collection {
        return ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->when($experienceId, function ($query) use ($experienceId) {
                $query->where('id', (int) $experienceId);
            })
            ->pluck('id')
            ->values();
    }

    private function getConfirmedBookings(
        Provider $provider,
        Collection $experienceIds,
        Carbon $startDate,
        Carbon $endDate,
    ): Collection {
        return ProviderBooking::query()
            ->with([
                'user.clientProfile',
                'experience',
                'schedule',
            ])
            ->where('provider_id', $provider->id)
            ->whereIn('provider_experience_id', $experienceIds)
            ->where('status', 'confirmed')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->get();
    }

    private function getCancelledBookings(
        Provider $provider,
        Collection $experienceIds,
        Carbon $startDate,
        Carbon $endDate,
    ): Collection {
        return ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereIn('provider_experience_id', $experienceIds)
            ->where('status', 'cancelled')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->get();
    }

    private function buildSummary(
        Provider $provider,
        Collection $experienceIds,
        Collection $confirmedBookings,
        Collection $cancelledBookings,
        Carbon $startDate,
        Carbon $endDate,
        mixed $experienceId,
    ): array {
        $totalRevenue = (float) $confirmedBookings->sum('provider_earning');
        $totalConfirmedBookings = $confirmedBookings->count();
        $totalCancelledBookings = $cancelledBookings->count();
        $totalGuests = (int) $confirmedBookings->sum('guests_count');

        $totalCapacity = (int) ProviderExperienceSchedule::query()
            ->where('provider_id', $provider->id)
            ->whereIn('provider_experience_id', $experienceIds)
            ->whereBetween('starts_at', [$startDate, $endDate])
            ->sum('capacity');

        $occupancyRate = $totalCapacity > 0
            ? round(($totalGuests / $totalCapacity) * 100, 1)
            : 0;

        $publishedExperiences = ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->where('status', 'published')
            ->when($experienceId, function ($query) use ($experienceId) {
                $query->where('id', (int) $experienceId);
            })
            ->count();

        $favoritesCount = CustomerFavoriteExperience::query()
            ->whereIn('provider_experience_id', $experienceIds)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $totalBookingsForCancellationRate = $totalConfirmedBookings + $totalCancelledBookings;

        $cancellationRate = $totalBookingsForCancellationRate > 0
            ? round(($totalCancelledBookings / $totalBookingsForCancellationRate) * 100, 1)
            : 0;

        return [
            'revenue' => [
                'value' => $totalRevenue,
                'formatted' => $this->formatMoney($totalRevenue),
            ],
            'confirmed_bookings' => [
                'value' => $totalConfirmedBookings,
                'formatted' => (string) $totalConfirmedBookings,
            ],
            'confirmed_guests' => [
                'value' => $totalGuests,
                'formatted' => (string) $totalGuests,
            ],
            'occupancy_rate' => [
                'value' => $occupancyRate,
                'formatted' => $occupancyRate . '%',
            ],
            'published_experiences' => [
                'value' => $publishedExperiences,
                'formatted' => (string) $publishedExperiences,
            ],
            'favorites' => [
                'value' => $favoritesCount,
                'formatted' => (string) $favoritesCount,
            ],
            'cancelled_bookings' => [
                'value' => $totalCancelledBookings,
                'formatted' => (string) $totalCancelledBookings,
            ],
            'cancellation_rate' => [
                'value' => $cancellationRate,
                'formatted' => $cancellationRate . '%',
            ],
        ];
    }

    private function buildAudience(Collection $confirmedBookings): array
    {
        return [
            'age_ranges' => $this->buildAgeRanges($confirmedBookings),
            'top_cities' => $this->buildProfileRanking(
                bookings: $confirmedBookings,
                field: 'residence_city',
                emptyLabel: 'Sin ciudad',
            ),
            'top_countries' => $this->buildProfileRanking(
                bookings: $confirmedBookings,
                field: 'country',
                emptyLabel: 'Sin país',
            ),
            'top_nationalities' => $this->buildProfileRanking(
                bookings: $confirmedBookings,
                field: 'nationality',
                emptyLabel: 'Sin nacionalidad',
            ),
            'top_languages' => $this->buildProfileRanking(
                bookings: $confirmedBookings,
                field: 'language',
                emptyLabel: 'Sin idioma',
            ),
        ];
    }

    private function buildAgeRanges(Collection $confirmedBookings): array
    {
        $ranges = [
            '18-24' => 0,
            '25-34' => 0,
            '35-44' => 0,
            '45-54' => 0,
            '55+' => 0,
            'Sin edad' => 0,
        ];

        foreach ($confirmedBookings as $booking) {
            $birthDate = $booking->user?->clientProfile?->birth_date;

            if (! $birthDate) {
                $ranges['Sin edad']++;
                continue;
            }

            $age = Carbon::parse($birthDate)->age;

            if ($age >= 18 && $age <= 24) {
                $ranges['18-24']++;
            } elseif ($age >= 25 && $age <= 34) {
                $ranges['25-34']++;
            } elseif ($age >= 35 && $age <= 44) {
                $ranges['35-44']++;
            } elseif ($age >= 45 && $age <= 54) {
                $ranges['45-54']++;
            } elseif ($age >= 55) {
                $ranges['55+']++;
            } else {
                $ranges['Sin edad']++;
            }
        }

        $total = max(array_sum($ranges), 1);

        return collect($ranges)
            ->map(fn ($count, $label) => [
                'label' => $label,
                'count' => $count,
                'percentage' => round(($count / $total) * 100, 1),
            ])
            ->values()
            ->all();
    }

    private function buildProfileRanking(
        Collection $bookings,
        string $field,
        string $emptyLabel,
        int $limit = 5,
    ): array {
        $values = [];

        foreach ($bookings as $booking) {
            $profile = $booking->user?->clientProfile;
            $value = $profile?->{$field};

            $label = filled($value) ? (string) $value : $emptyLabel;

            $values[$label] = ($values[$label] ?? 0) + 1;
        }

        arsort($values);

        $total = max(array_sum($values), 1);

        return collect($values)
            ->take($limit)
            ->map(fn ($count, $label) => [
                'label' => $label,
                'count' => $count,
                'percentage' => round(($count / $total) * 100, 1),
            ])
            ->values()
            ->all();
    }

    private function buildConversion(
        Collection $experienceIds,
        Collection $confirmedBookings,
        Carbon $startDate,
        Carbon $endDate,
    ): array {
        $favorites = CustomerFavoriteExperience::query()
            ->whereIn('provider_experience_id', $experienceIds)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->get();

        $convertedFavorites = 0;

        foreach ($favorites as $favorite) {
            $converted = ProviderBooking::query()
                ->where('user_id', $favorite->user_id)
                ->where('provider_experience_id', $favorite->provider_experience_id)
                ->where('status', 'confirmed')
                ->where('created_at', '>=', $favorite->created_at)
                ->exists();

            if ($converted) {
                $convertedFavorites++;
            }
        }

        $favoritesCount = $favorites->count();

        return [
            'favorites_count' => $favoritesCount,
            'converted_favorites_count' => $convertedFavorites,
            'favorites_to_bookings_rate' => $favoritesCount > 0
                ? round(($convertedFavorites / $favoritesCount) * 100, 1)
                : 0,

            /**
             * No hay tabla de eventos todavía.
             * Por eso views/start_booking quedan null.
             */
            'views_count' => null,
            'views_to_bookings_rate' => null,
            'confirmed_bookings_count' => $confirmedBookings->count(),
        ];
    }

    private function buildUpcomingSchedules(
        Provider $provider,
        Collection $experienceIds,
        int $limit = 6,
    ): array {
        return ProviderExperienceSchedule::query()
            ->with('experience')
            ->where('provider_id', $provider->id)
            ->whereIn('provider_experience_id', $experienceIds)
            ->where('status', 'active')
            ->where('starts_at', '>=', now())
            ->orderBy('starts_at')
            ->limit($limit)
            ->get()
            ->map(function (ProviderExperienceSchedule $schedule) {
                $booked = (int) ProviderBooking::query()
                    ->where('provider_experience_schedule_id', $schedule->id)
                    ->where('status', 'confirmed')
                    ->sum('guests_count');

                $capacity = max((int) $schedule->capacity, 1);
                $occupancyRate = round(($booked / $capacity) * 100, 1);

                return [
                    'id' => $schedule->id,
                    'provider_experience_id' => $schedule->provider_experience_id,
                    'experience_title' => $schedule->experience?->title ?? 'Experiencia',
                    'starts_at' => optional($schedule->starts_at)->toISOString(),
                    'capacity' => (int) $schedule->capacity,
                    'booked' => $booked,
                    'available' => max((int) $schedule->capacity - $booked, 0),
                    'occupancy_rate' => $occupancyRate,
                    'price' => (float) $schedule->price,
                    'currency' => $schedule->currency,
                    'status' => $schedule->status,
                    'needs_promotion' => $occupancyRate < 50,
                ];
            })
            ->values()
            ->all();
    }

    private function buildOccupancyByWeekday(
        Provider $provider,
        Collection $experienceIds,
        Carbon $startDate,
        Carbon $endDate,
    ): array {
        $weekdays = $this->emptyWeekdays();

        $schedules = ProviderExperienceSchedule::query()
            ->where('provider_id', $provider->id)
            ->whereIn('provider_experience_id', $experienceIds)
            ->whereBetween('starts_at', [$startDate, $endDate])
            ->get();

        foreach ($schedules as $schedule) {
            $key = $this->weekdayKey($schedule->starts_at);

            $booked = (int) ProviderBooking::query()
                ->where('provider_experience_schedule_id', $schedule->id)
                ->where('status', 'confirmed')
                ->sum('guests_count');

            $weekdays[$key]['capacity'] += (int) $schedule->capacity;
            $weekdays[$key]['booked'] += $booked;
        }

        return collect($weekdays)
            ->map(function ($item) {
                $capacity = max((int) $item['capacity'], 0);
                $booked = max((int) $item['booked'], 0);

                return [
                    ...$item,
                    'occupancy_rate' => $capacity > 0
                        ? round(($booked / $capacity) * 100, 1)
                        : 0,
                ];
            })
            ->values()
            ->all();
    }

    private function buildBookingHeatmap(Collection $confirmedBookings): array
    {
        $days = [
            'monday' => 'L',
            'tuesday' => 'M',
            'wednesday' => 'X',
            'thursday' => 'J',
            'friday' => 'V',
            'saturday' => 'S',
            'sunday' => 'D',
        ];

        $blocks = [
            'morning' => 'AM',
            'afternoon' => 'PM',
            'night' => 'NOC',
        ];

        $matrix = [];

        foreach ($days as $dayKey => $dayLabel) {
            foreach ($blocks as $blockKey => $blockLabel) {
                $matrix[$dayKey][$blockKey] = [
                    'day' => $dayKey,
                    'day_label' => $dayLabel,
                    'block' => $blockKey,
                    'block_label' => $blockLabel,
                    'count' => 0,
                    'intensity' => 0,
                ];
            }
        }

        foreach ($confirmedBookings as $booking) {
            $createdAt = Carbon::parse($booking->created_at);

            $dayKey = strtolower($createdAt->englishDayOfWeek);
            $blockKey = $this->timeBlock($createdAt);

            if (isset($matrix[$dayKey][$blockKey])) {
                $matrix[$dayKey][$blockKey]['count']++;
            }
        }

        $max = collect($matrix)
            ->flatMap(fn ($blocks) => $blocks)
            ->max('count') ?: 0;

        foreach ($matrix as $dayKey => $dayBlocks) {
            foreach ($dayBlocks as $blockKey => $item) {
                $matrix[$dayKey][$blockKey]['intensity'] = $max > 0
                    ? (int) ceil(($item['count'] / $max) * 5)
                    : 0;
            }
        }

        return collect($matrix)
            ->map(fn ($blocks) => array_values($blocks))
            ->flatten(1)
            ->values()
            ->all();
    }

    private function buildBookingLeadTime(Collection $confirmedBookings): array
    {
        $ranges = [
            '0-2 días' => 0,
            '3-7 días' => 0,
            '8-14 días' => 0,
            '15+ días' => 0,
            'Sin fecha' => 0,
        ];

        $totalDays = 0;
        $validCount = 0;

        foreach ($confirmedBookings as $booking) {
            $tripDate = $booking->schedule?->starts_at ?? $booking->booking_date;

            if (! $tripDate || ! $booking->created_at) {
                $ranges['Sin fecha']++;
                continue;
            }

            $days = Carbon::parse($booking->created_at)
                ->startOfDay()
                ->diffInDays(Carbon::parse($tripDate)->startOfDay(), false);

            if ($days < 0) {
                $ranges['Sin fecha']++;
                continue;
            }

            $totalDays += $days;
            $validCount++;

            if ($days <= 2) {
                $ranges['0-2 días']++;
            } elseif ($days <= 7) {
                $ranges['3-7 días']++;
            } elseif ($days <= 14) {
                $ranges['8-14 días']++;
            } else {
                $ranges['15+ días']++;
            }
        }

        $total = max(array_sum($ranges), 1);

        return [
            'average_days' => $validCount > 0
                ? round($totalDays / $validCount, 1)
                : 0,
            'ranges' => collect($ranges)
                ->map(fn ($count, $label) => [
                    'label' => $label,
                    'count' => $count,
                    'percentage' => round(($count / $total) * 100, 1),
                ])
                ->values()
                ->all(),
        ];
    }

    private function buildExperiencePerformance(
        Provider $provider,
        Collection $experienceIds,
        Collection $confirmedBookings,
        Carbon $startDate,
        Carbon $endDate,
    ): array {
        $experiences = ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->whereIn('id', $experienceIds)
            ->get();

        $items = $experiences->map(function (ProviderExperience $experience) use (
            $confirmedBookings,
            $startDate,
            $endDate
        ) {
            $bookings = $confirmedBookings
                ->where('provider_experience_id', $experience->id);

            $bookingsCount = $bookings->count();
            $guests = (int) $bookings->sum('guests_count');
            $revenue = (float) $bookings->sum('provider_earning');

            $capacity = (int) ProviderExperienceSchedule::query()
                ->where('provider_experience_id', $experience->id)
                ->whereBetween('starts_at', [$startDate, $endDate])
                ->sum('capacity');

            $favorites = CustomerFavoriteExperience::query()
                ->where('provider_experience_id', $experience->id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->count();

            $occupancyRate = $capacity > 0
                ? round(($guests / $capacity) * 100, 1)
                : 0;

            $favoriteConversionRate = $favorites > 0
                ? round(($bookingsCount / $favorites) * 100, 1)
                : 0;

            return [
                'id' => $experience->id,
                'title' => $experience->title,
                'category' => $experience->category,
                'status' => $experience->status,
                'capacity' => (int) $experience->capacity,
                'bookings_count' => $bookingsCount,
                'guests_count' => $guests,
                'revenue' => $revenue,
                'revenue_formatted' => $this->formatMoney($revenue),
                'period_capacity' => $capacity,
                'occupancy_rate' => $occupancyRate,
                'favorites_count' => $favorites,
                'favorites_to_bookings_rate' => $favoriteConversionRate,
            ];
        })->values();

        return [
            'top_by_revenue' => $items
                ->sortByDesc('revenue')
                ->take(5)
                ->values()
                ->all(),
            'top_by_bookings' => $items
                ->sortByDesc('guests_count')
                ->take(5)
                ->values()
                ->all(),
            'top_by_occupancy' => $items
                ->sortByDesc('occupancy_rate')
                ->take(5)
                ->values()
                ->all(),
            'low_conversion' => $items
                ->filter(fn ($item) => $item['favorites_count'] >= 1 && $item['favorites_to_bookings_rate'] < 20)
                ->sortBy('favorites_to_bookings_rate')
                ->take(5)
                ->values()
                ->all(),
        ];
    }

    private function buildLoyalty(
        Provider $provider,
        Collection $confirmedBookings,
        Carbon $startDate,
    ): array {
        $userIds = $confirmedBookings
            ->pluck('user_id')
            ->filter()
            ->unique()
            ->values();

        $newCustomers = 0;
        $recurrentCustomers = 0;

        foreach ($userIds as $userId) {
            $hadPreviousBooking = ProviderBooking::query()
                ->where('provider_id', $provider->id)
                ->where('user_id', $userId)
                ->where('status', 'confirmed')
                ->where('created_at', '<', $startDate)
                ->exists();

            if ($hadPreviousBooking) {
                $recurrentCustomers++;
            } else {
                $newCustomers++;
            }
        }

        $totalCustomers = $userIds->count();

        $vipCustomers = ProviderBooking::query()
            ->selectRaw('user_id, COUNT(*) as bookings_count, SUM(provider_earning) as total_spent')
            ->where('provider_id', $provider->id)
            ->where('status', 'confirmed')
            ->whereNotNull('user_id')
            ->groupBy('user_id')
            ->havingRaw('COUNT(*) >= 3')
            ->havingRaw('SUM(provider_earning) >= 12000')
            ->count();

        return [
            'unique_customers' => $totalCustomers,
            'new_customers' => $newCustomers,
            'recurrent_customers' => $recurrentCustomers,
            'new_customers_rate' => $totalCustomers > 0
                ? round(($newCustomers / $totalCustomers) * 100, 1)
                : 0,
            'recurrent_customers_rate' => $totalCustomers > 0
                ? round(($recurrentCustomers / $totalCustomers) * 100, 1)
                : 0,
            'vip_customers_count' => $vipCustomers,
        ];
    }

    private function buildAvailableExperiences(Provider $provider): array
    {
        return ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->orderBy('title')
            ->get()
            ->map(fn (ProviderExperience $experience) => [
                'id' => $experience->id,
                'title' => $experience->title,
                'status' => $experience->status,
            ])
            ->values()
            ->all();
    }

    private function resolveDateRange(array $filters, string $period): array
    {
        $now = now();

        if ($period === '7d') {
            return [
                $now->copy()->subDays(6)->startOfDay(),
                $now->copy()->endOfDay(),
            ];
        }

        if ($period === '90d') {
            return [
                $now->copy()->subDays(89)->startOfDay(),
                $now->copy()->endOfDay(),
            ];
        }

        if ($period === 'year') {
            return [
                $now->copy()->startOfYear(),
                $now->copy()->endOfYear(),
            ];
        }

        if ($period === 'custom') {
            $startDate = $filters['start_date'] ?? null;
            $endDate = $filters['end_date'] ?? null;

            if ($startDate && $endDate) {
                return [
                    Carbon::parse($startDate)->startOfDay(),
                    Carbon::parse($endDate)->endOfDay(),
                ];
            }
        }

        return [
            $now->copy()->subDays(29)->startOfDay(),
            $now->copy()->endOfDay(),
        ];
    }

    private function emptyWeekdays(): array
    {
        return [
            'monday' => [
                'day' => 'monday',
                'label' => 'L',
                'capacity' => 0,
                'booked' => 0,
            ],
            'tuesday' => [
                'day' => 'tuesday',
                'label' => 'M',
                'capacity' => 0,
                'booked' => 0,
            ],
            'wednesday' => [
                'day' => 'wednesday',
                'label' => 'X',
                'capacity' => 0,
                'booked' => 0,
            ],
            'thursday' => [
                'day' => 'thursday',
                'label' => 'J',
                'capacity' => 0,
                'booked' => 0,
            ],
            'friday' => [
                'day' => 'friday',
                'label' => 'V',
                'capacity' => 0,
                'booked' => 0,
            ],
            'saturday' => [
                'day' => 'saturday',
                'label' => 'S',
                'capacity' => 0,
                'booked' => 0,
            ],
            'sunday' => [
                'day' => 'sunday',
                'label' => 'D',
                'capacity' => 0,
                'booked' => 0,
            ],
        ];
    }

    private function weekdayKey(Carbon $date): string
    {
        return strtolower($date->englishDayOfWeek);
    }

    private function timeBlock(Carbon $date): string
    {
        $hour = (int) $date->format('H');

        if ($hour >= 5 && $hour <= 11) {
            return 'morning';
        }

        if ($hour >= 12 && $hour <= 17) {
            return 'afternoon';
        }

        return 'night';
    }

    private function formatMoney(float $amount): string
    {
        return 'RD$' . number_format($amount, 2);
    }
}