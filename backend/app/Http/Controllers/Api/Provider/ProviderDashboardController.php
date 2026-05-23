<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\Provider;
use App\Models\ProviderBooking;
use App\Models\ProviderExperience;
use App\Models\ProviderReview;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProviderDashboardController extends Controller
{
    /**
     * Devuelve todo el dashboard del afiliado conectado a la base de datos.
     *
     * No devuelve valores quemados.
     * Si no hay data, devuelve 0 o arrays vacíos.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'message' => 'No autenticado. Debes iniciar sesión nuevamente.',
            ], 401);
        }

        $provider = Provider::query()
            ->where('user_id', $user->id)
            ->first();

        if (! $provider) {
            return response()->json([
                'message' => 'Este usuario no tiene un perfil de afiliado asociado.',
            ], 404);
        }

        $provider = Provider::query()
            ->where('user_id', $user->id)
            ->first();

        if (! $provider) {
            return response()->json([
                'message' => 'Tu usuario todavía no tiene un perfil de afiliado asociado.',
            ], 404);
        }

        $now = now();

        $monthStart = $now->copy()->startOfMonth();
        $monthEnd = $now->copy()->endOfMonth();

        $previousMonthStart = $now->copy()->subMonthNoOverflow()->startOfMonth();
        $previousMonthEnd = $now->copy()->subMonthNoOverflow()->endOfMonth();

        /*
        |--------------------------------------------------------------------------
        | Ganancias del mes
        |--------------------------------------------------------------------------
        |
        | Se toma provider_earning porque permite manejar comisión de plataforma.
        | No usamos total_amount como ganancia real del afiliado.
        |
        */
        $monthlyEarnings = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereBetween('booking_date', [$monthStart, $monthEnd])
            ->whereIn('status', ['confirmed', 'completed'])
            ->sum('provider_earning');

        $previousMonthlyEarnings = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereBetween('booking_date', [$previousMonthStart, $previousMonthEnd])
            ->whereIn('status', ['confirmed', 'completed'])
            ->sum('provider_earning');

        /*
        |--------------------------------------------------------------------------
        | Reservas activas
        |--------------------------------------------------------------------------
        |
        | Activas = pendientes o confirmadas que todavía no han sido canceladas.
        |
        */
        $activeBookings = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->count();

        $previousMonthActiveBookings = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereBetween('booking_date', [$previousMonthStart, $previousMonthEnd])
            ->whereIn('status', ['pending', 'confirmed'])
            ->count();

        /*
        |--------------------------------------------------------------------------
        | Experiencias publicadas
        |--------------------------------------------------------------------------
        |
        | Reemplaza "vistas totales" para no inventar una métrica que todavía
        | no tiene tracking real.
        |
        */
        $publishedExperiences = ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->where('status', 'published')
            ->where('is_active', true)
            ->count();

        $publishedThisMonth = ProviderExperience::query()
            ->where('provider_id', $provider->id)
            ->where('status', 'published')
            ->where('is_active', true)
            ->whereBetween('created_at', [$monthStart, $monthEnd])
            ->count();

        /*
        |--------------------------------------------------------------------------
        | Rating promedio
        |--------------------------------------------------------------------------
        */
        $averageRating = ProviderReview::query()
            ->where('provider_id', $provider->id)
            ->where('is_visible', true)
            ->avg('rating');

        $averageRating = round((float) ($averageRating ?? 0), 1);

        $currentMonthRating = ProviderReview::query()
            ->where('provider_id', $provider->id)
            ->where('is_visible', true)
            ->whereBetween('created_at', [$monthStart, $monthEnd])
            ->avg('rating');

        $previousMonthRating = ProviderReview::query()
            ->where('provider_id', $provider->id)
            ->where('is_visible', true)
            ->whereBetween('created_at', [$previousMonthStart, $previousMonthEnd])
            ->avg('rating');

        /*
        |--------------------------------------------------------------------------
        | Próximas reservas
        |--------------------------------------------------------------------------
        */
        $upcomingBookings = $this->buildUpcomingBookings(
            providerId: $provider->id,
            now: $now,
            limit: 5,
        );

        /*
        |--------------------------------------------------------------------------
        | Análisis rápido
        |--------------------------------------------------------------------------
        */
        $totalBookings = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->count();

        $monthlyBookings = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereBetween('booking_date', [$monthStart, $monthEnd])
            ->count();

        $confirmedOrCompletedBookings = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereIn('status', ['confirmed', 'completed'])
            ->count();

        $confirmationRate = $totalBookings > 0
            ? round(($confirmedOrCompletedBookings / $totalBookings) * 100, 1)
            : 0;

        $cancelledThisMonth = ProviderBooking::query()
            ->where('provider_id', $provider->id)
            ->whereBetween('booking_date', [$monthStart, $monthEnd])
            ->where('status', 'cancelled')
            ->count();

        $monthlyRevenueSeries = $this->monthlyRevenueSeries($provider->id, $now);

        return response()->json([
            'data' => [
                'affiliate_name' => $provider->business_name
                    ?? $provider->name
                    ?? $user->name
                    ?? 'Afiliado',

                'provider_status' => $provider->status ?? null,

                'stats' => [
                    'monthly_earnings' => [
                        'value' => (float) $monthlyEarnings,
                        'formatted' => $this->money($monthlyEarnings),
                        'change' => $this->percentChange($monthlyEarnings, $previousMonthlyEarnings),
                        'change_label' => $this->percentChangeLabel($monthlyEarnings, $previousMonthlyEarnings),
                    ],

                    'active_bookings' => [
                        'value' => $activeBookings,
                        'formatted' => (string) $activeBookings,
                        'change' => $this->percentChange($activeBookings, $previousMonthActiveBookings),
                        'change_label' => $this->percentChangeLabel($activeBookings, $previousMonthActiveBookings),
                    ],

                    'published_experiences' => [
                        'value' => $publishedExperiences,
                        'formatted' => (string) $publishedExperiences,
                        'change' => $publishedThisMonth,
                        'change_label' => '+' . $publishedThisMonth . ' este mes',
                    ],

                    'average_rating' => [
                        'value' => $averageRating,
                        'formatted' => number_format($averageRating, 1),
                        'change' => $this->ratingChange($currentMonthRating, $previousMonthRating),
                        'change_label' => $this->ratingChangeLabel($currentMonthRating, $previousMonthRating),
                    ],
                ],

                'upcoming_bookings' => $upcomingBookings,

                'quick_analysis' => [
                    'confirmation_rate' => $confirmationRate,
                    'monthly_bookings' => $monthlyBookings,
                    'total_bookings' => $totalBookings,
                    'cancelled_this_month' => $cancelledThisMonth,
                    'satisfaction' => $averageRating,
                    'monthly_revenue_series' => $monthlyRevenueSeries,
                ],
            ],
        ]);
    }

    /**
     * Devuelve todas las próximas salidas con reservas del afiliado.
     *
     * A diferencia del dashboard, aquí NO limitamos a 5.
     * Agrupamos por experiencia + fecha programada para que una misma salida
     * aparezca una sola vez aunque tenga varias reservas de distintos clientes.
     */
    public function upcomingBookings(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'message' => 'No autenticado. Debes iniciar sesión nuevamente.',
            ], 401);
        }

        $provider = Provider::query()
            ->where('user_id', $user->id)
            ->first();

        if (! $provider) {
            return response()->json([
                'message' => 'Tu usuario todavía no tiene un perfil de afiliado asociado.',
            ], 404);
        }

        $bookings = $this->buildUpcomingBookings(
            providerId: $provider->id,
            now: now(),
            limit: null,
        );

        return response()->json([
            'summary' => [
                'total_groups' => $bookings->count(),
                'total_bookings' => (int) $bookings->sum('bookings_count'),
                'total_travelers' => (int) $bookings->sum('guests'),
            ],
            'data' => $bookings,
        ]);
    }

    private function buildUpcomingBookings(
        int $providerId,
        Carbon $now,
        ?int $limit = 5,
    ) {
        $query = ProviderBooking::query()
            ->join(
                'provider_experiences as experiences',
                'experiences.id',
                '=',
                'provider_bookings.provider_experience_id'
            )
            ->join(
                'provider_experience_schedules as schedules',
                'schedules.id',
                '=',
                'provider_bookings.provider_experience_schedule_id'
            )
            ->where('provider_bookings.provider_id', $providerId)
            ->where('schedules.starts_at', '>=', $now)
            ->whereIn('provider_bookings.status', ['pending', 'confirmed'])
            ->groupBy(
                'provider_bookings.provider_experience_id',
                'provider_bookings.provider_experience_schedule_id',
                'experiences.title',
                'schedules.starts_at'
            )
            ->orderBy('schedules.starts_at');

        if ($limit !== null) {
            $query->limit($limit);
        }

        return $query
            ->get([
                DB::raw('MIN(provider_bookings.id) as id'),
                DB::raw('MIN(provider_bookings.booking_code) as booking_code'),
                'provider_bookings.provider_experience_id',
                'provider_bookings.provider_experience_schedule_id',
                'experiences.title as tour',
                'schedules.starts_at as schedule_starts_at',
                DB::raw('COUNT(provider_bookings.id) as bookings_count'),
                DB::raw('SUM(provider_bookings.guests_count) as guests'),
                DB::raw("SUM(CASE WHEN provider_bookings.status = 'pending' THEN 1 ELSE 0 END) as pending_count"),
            ])
            ->map(function ($booking) {
                $startsAt = $booking->schedule_starts_at
                    ? Carbon::parse($booking->schedule_starts_at)
                    : null;

                $bookingsCount = (int) $booking->bookings_count;

                $status = ((int) $booking->pending_count > 0)
                    ? 'pending'
                    : 'confirmed';

                return [
                    'id' => (int) $booking->id,
                    'booking_code' => $bookingsCount === 1
                        ? (string) $booking->booking_code
                        : $bookingsCount . ' reservas',

                    'provider_experience_id' => (int) $booking->provider_experience_id,
                    'provider_experience_schedule_id' => (int) $booking->provider_experience_schedule_id,

                    'tour' => $booking->tour ?? 'Experiencia no disponible',

                    'date' => $startsAt?->toISOString(),
                    'date_label' => $startsAt?->translatedFormat('d M, h:i A'),

                    'guests' => (int) $booking->guests,
                    'bookings_count' => $bookingsCount,

                    'status' => $status,
                    'status_label' => $this->bookingStatusLabel($status),
                ];
            })
            ->values();
    }

    private function monthlyRevenueSeries(int $providerId, Carbon $now): array
    {
        $series = [];

        $cursor = $now->copy()->subMonths(5)->startOfMonth();

        for ($i = 0; $i < 6; $i++) {
            $start = $cursor->copy()->startOfMonth();
            $end = $cursor->copy()->endOfMonth();

            $amount = ProviderBooking::query()
                ->where('provider_id', $providerId)
                ->whereBetween('booking_date', [$start, $end])
                ->whereIn('status', ['confirmed', 'completed'])
                ->sum('provider_earning');

            $series[] = [
                'month' => $start->format('Y-m'),
                'label' => $start->translatedFormat('M'),
                'amount' => (float) $amount,
                'formatted' => $this->money($amount),
            ];

            $cursor->addMonth();
        }

        return $series;
    }

    private function money(float|int|string $amount): string
    {
        return 'RD$' . number_format((float) $amount, 2);
    }

    private function percentChange(float|int|string $current, float|int|string $previous): float
    {
        $current = (float) $current;
        $previous = (float) $previous;

        if ($previous === 0.0) {
            return $current > 0 ? 100.0 : 0.0;
        }

        return round((($current - $previous) / abs($previous)) * 100, 1);
    }

    private function percentChangeLabel(float|int|string $current, float|int|string $previous): string
    {
        $change = $this->percentChange($current, $previous);

        if ($change > 0) {
            return '+' . $change . '%';
        }

        return $change . '%';
    }

    private function ratingChange(float|int|string|null $current, float|int|string|null $previous): float
    {
        $current = (float) ($current ?? 0);
        $previous = (float) ($previous ?? 0);

        return round($current - $previous, 1);
    }

    private function ratingChangeLabel(float|int|string|null $current, float|int|string|null $previous): string
    {
        $change = $this->ratingChange($current, $previous);

        if ($change > 0) {
            return '+' . number_format($change, 1);
        }

        return number_format($change, 1);
    }

    private function bookingStatusLabel(string $status): string
    {
        return match ($status) {
            'pending' => 'Pendiente',
            'confirmed' => 'Confirmada',
            'completed' => 'Completada',
            'cancelled' => 'Cancelada',
            default => 'Desconocida',
        };
    }
}