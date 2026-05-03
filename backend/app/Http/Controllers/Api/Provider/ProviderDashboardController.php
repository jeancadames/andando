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
        $upcomingBookings = ProviderBooking::query()
            ->with('experience:id,title')
            ->where('provider_id', $provider->id)
            ->where('booking_date', '>=', $now)
            ->whereIn('status', ['pending', 'confirmed'])
            ->orderBy('booking_date')
            ->limit(5)
            ->get()
            ->map(function (ProviderBooking $booking) {
                return [
                    'id' => $booking->id,
                    'booking_code' => $booking->booking_code,
                    'tour' => $booking->experience?->title ?? 'Experiencia no disponible',
                    'date' => $booking->booking_date?->toISOString(),
                    'date_label' => $booking->booking_date?->translatedFormat('d M, h:i A'),
                    'guests' => $booking->guests_count,
                    'status' => $booking->status,
                    'status_label' => $this->bookingStatusLabel($booking->status),
                ];
            })
            ->values();

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