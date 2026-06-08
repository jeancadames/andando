<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\ProviderBooking;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controlador de transacciones del cliente.
 *
 * Por ahora deriva las transacciones desde las reservas reales.
 * Más adelante, cuando Azul esté activo, este endpoint podrá leer desde
 * payment_transactions directamente.
 */
class ClientPaymentTransactionController extends Controller
{
    /**
     * Lista transacciones recientes del cliente autenticado.
     */
    public function index(Request $request): JsonResponse
    {
        $transactions = ProviderBooking::query()
            ->with(['experience'])
            ->where('user_id', $request->user()->id)
            ->latest('created_at')
            ->limit(10)
            ->get()
            ->map(function (ProviderBooking $booking) {
                return [
                    'id' => $booking->id,
                    'booking_id' => $booking->id,
                    'title' => $booking->experience?->title ?? 'Reserva AndanDO',
                    'date' => $booking->created_at?->toIso8601String(),
                    'date_label' => $this->formatShortSpanishDate($booking->created_at),
                    'amount' => -1 * (float) $booking->total_amount,
                    'currency' => 'DOP',
                    'payment_method_label' => null,
                    'status' => $this->mapStatus($booking->status),
                    'status_label' => $this->mapStatusLabel($booking->status),
                    'type' => 'charge',
                ];
            })
            ->values();

        return response()->json([
            'message' => 'Transacciones obtenidas correctamente.',
            'data' => [
                'transactions' => $transactions,
            ],
        ]);
    }

    private function mapStatus(string $status): string
    {
        return match ($status) {
            'confirmed', 'completed' => 'completed',
            'pending' => 'pending',
            'cancelled' => 'cancelled',
            default => 'pending',
        };
    }

    private function mapStatusLabel(string $status): string
    {
        return match ($status) {
            'confirmed', 'completed' => 'Completado',
            'pending' => 'Pendiente',
            'cancelled' => 'Cancelado',
            default => 'Pendiente',
        };
    }

    private function formatShortSpanishDate($date): ?string
    {
        if (! $date) {
            return null;
        }

        $months = [
            1 => 'ene',
            2 => 'feb',
            3 => 'mar',
            4 => 'abr',
            5 => 'may',
            6 => 'jun',
            7 => 'jul',
            8 => 'ago',
            9 => 'sep',
            10 => 'oct',
            11 => 'nov',
            12 => 'dic',
        ];

        return $date->day . ' ' . $months[(int) $date->month] . ' ' . $date->year;
    }
}