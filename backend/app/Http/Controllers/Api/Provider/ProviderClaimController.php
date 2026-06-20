<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\BookingClaim;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProviderClaimController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $provider = $request->user()->provider;

        if (! $provider) {
            abort(403, 'No tienes un perfil de proveedor asociado.');
        }

        $claims = BookingClaim::query()
            ->with([
                'user',
                'booking.experience',
                'booking.schedule',
            ])
            ->where('provider_id', $provider->id)
            ->latest()
            ->get()
            ->map(fn (BookingClaim $claim) => $this->formatClaim($claim))
            ->values();

        return response()->json([
            'message' => 'Reclamos obtenidos correctamente.',
            'data' => $claims,
        ]);
    }

    public function show(Request $request, BookingClaim $claim): JsonResponse
    {
        $provider = $request->user()->provider;

        if (! $provider || $claim->provider_id !== $provider->id) {
            abort(403, 'No tienes permiso para ver este reclamo.');
        }

        $claim->load([
            'user',
            'booking.experience',
            'booking.schedule',
        ]);

        return response()->json([
            'message' => 'Reclamo obtenido correctamente.',
            'data' => $this->formatClaim($claim),
        ]);
    }

    public function reply(Request $request, BookingClaim $claim): JsonResponse
    {
        $provider = $request->user()->provider;

        if (! $provider || $claim->provider_id !== $provider->id) {
            abort(403, 'No tienes permiso para responder este reclamo.');
        }

        $data = $request->validate([
            'provider_response' => [
                'required',
                'string',
                'min:10',
                'max:1000',
            ],
        ]);

        $claim->update([
            'provider_response' => $data['provider_response'],
            'provider_replied_at' => now(),
            'status' => 'provider_replied',
        ]);

        $claim->load([
            'user',
            'booking.experience',
            'booking.schedule',
        ]);

        $claim->user?->notify(
            new ClaimRespondedNotification($claim)
        );

        return response()->json([
            'message' => 'Respuesta enviada correctamente.',
            'data' => $this->formatClaim($claim),
        ]);
    }

    private function formatClaim(BookingClaim $claim): array
    {
        $booking = $claim->booking;
        $experience = $booking?->experience;
        $schedule = $booking?->schedule;
        $user = $claim->user;

        return [
            'id' => $claim->id,
            'provider_booking_id' => $claim->provider_booking_id,
            'booking_code' => $booking?->booking_code,
            'booking_status' => $booking?->status,
            'customer_name' => $user?->name ?? $booking?->customer_name,
            'customer_email' => $user?->email ?? $booking?->customer_email,
            'experience_title' => $experience?->title ?? 'Experiencia',
            'booking_date' => $booking?->booking_date?->toIso8601String(),
            'starts_at' => $schedule?->starts_at?->toIso8601String()
                ?? $booking?->booking_date?->toIso8601String(),
            'reason' => $claim->reason,
            'description' => $claim->description,
            'status' => $claim->status,
            'provider_response' => $claim->provider_response,
            'provider_replied_at' => $claim->provider_replied_at?->toIso8601String(),
            'resolved_at' => $claim->resolved_at?->toIso8601String(),
            'created_at' => $claim->created_at?->toIso8601String(),
        ];
    }
}