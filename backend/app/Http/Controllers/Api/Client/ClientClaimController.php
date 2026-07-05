<?php

namespace App\Http\Controllers\Api\Client;

use App\Services\Payments\SchedulePayoutHoldService;
use App\Services\PushNotificationService;

use App\Models\User;
use App\Notifications\Admin\NewClaimForReviewNotification;

use App\Notifications\Claim\ClaimReceivedNotification;

use App\Http\Controllers\Controller;
use App\Models\ProviderBooking;
use App\Models\BookingClaim;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;


class ClientClaimController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $claims = BookingClaim::query()
            ->with([
                'booking.experience',
                'booking.schedule',
            ])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get()
            ->map(fn (BookingClaim $claim) => $this->formatClaim($claim))
            ->values();

        return response()->json([
            'message' => 'Reclamos obtenidos correctamente.',
            'data' => $claims,
        ]);
    }

    public function store(
        Request $request,
        SchedulePayoutHoldService $payoutHoldService,
        PushNotificationService $pushNotificationService,
    ): JsonResponse
    {
        $data = $request->validate([
            'provider_booking_id' => [
                'required',
                'integer',
                'exists:provider_bookings,id',
            ],
            'reason' => [
                'required',
                'string',
                'max:120',
            ],
            'description' => [
                'nullable',
                'string',
                'max:500',
            ],
        ]);

        $booking = ProviderBooking::query()
            ->with(['claim', 'experience', 'schedule'])
            ->where('id', $data['provider_booking_id'])
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        if ($booking->status === 'cancelled') {
            return response()->json([
                'message' => 'No puedes crear reclamos para reservas canceladas.',
            ], 422);
        }

        if ($booking->claim !== null) {
            return response()->json([
                'message' => 'Ya existe un reclamo para esta reserva.',
            ], 422);
        }

        $claim = BookingClaim::create([
            'provider_booking_id' => $booking->id,
            'provider_id' => $booking->provider_id,
            'user_id' => $request->user()->id,
            'reason' => $data['reason'],
            'description' => $data['description'] ?? '',
            'status' => 'pending',
        ]);

        $payoutHoldService->holdByClaim($claim);

        $claim->load([
            'booking.experience',
            'booking.schedule',
            'provider.user',
        ]);

        $request->user()->notify(
            new ClaimReceivedNotification($claim)
        );

        User::query()
            ->where('type', 'admin')
            ->get()
            ->each(function (User $admin) use ($claim) {
                $admin->notify(
                    new NewClaimForReviewNotification($claim)
                );
            });

        if ($claim->provider?->user) {
            $experienceName = $claim->booking?->experience?->title
                ?? 'una experiencia';

            $customerName = $request->user()->name ?? 'Un cliente';

            $pushNotificationService->sendToUser(
                user: $claim->provider->user,
                title: 'Nuevo reclamo recibido',
                body: "{$customerName} abrió un reclamo sobre {$experienceName}.",
                data: [
                    'type' => 'claim_opened',
                    'claim_id' => (string) $claim->id,
                    'booking_id' => (string) $claim->provider_booking_id,
                    'role' => 'provider',
                ],
                category: PushNotificationService::CATEGORY_CLAIM,
            );
        }

        return response()->json([
            'message' => 'Reclamo creado correctamente.',
            'data' => $this->formatClaim($claim),
        ], 201);
    }

    public function show(Request $request, BookingClaim $claim): JsonResponse
    {
        if ($claim->user_id !== $request->user()->id) {
            abort(403, 'No tienes permiso para ver este reclamo.');
        }

        $claim->load([
            'booking.experience',
            'booking.schedule',
            'provider.user',
        ]);

        return response()->json([
            'message' => 'Reclamo obtenido correctamente.',
            'data' => $this->formatClaim($claim),
        ]);
    }

    private function formatClaim(BookingClaim $claim): array
    {
        $booking = $claim->booking;
        $experience = $booking?->experience;
        $schedule = $booking?->schedule;

        return [
            'id' => $claim->id,
            'provider_booking_id' => $claim->provider_booking_id,
            'booking_code' => $booking?->booking_code,
            'booking_status' => $booking?->status,
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