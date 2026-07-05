<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserNotificationPreference;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationPreferenceController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $preference = UserNotificationPreference::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'push_enabled' => true,
                'booking_notifications_enabled' => true,
                'message_notifications_enabled' => true,
                'payment_notifications_enabled' => true,
                'claim_notifications_enabled' => true,
                'payout_notifications_enabled' => true,
                'reminder_notifications_enabled' => true,
            ]
        );

        return response()->json([
            'data' => $preference,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'push_enabled' => ['sometimes', 'boolean'],
            'booking_notifications_enabled' => ['sometimes', 'boolean'],
            'message_notifications_enabled' => ['sometimes', 'boolean'],
            'payment_notifications_enabled' => ['sometimes', 'boolean'],
            'claim_notifications_enabled' => ['sometimes', 'boolean'],
            'payout_notifications_enabled' => ['sometimes', 'boolean'],
            'reminder_notifications_enabled' => ['sometimes', 'boolean'],
        ]);

        $preference = UserNotificationPreference::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'push_enabled' => true,
                'booking_notifications_enabled' => true,
                'message_notifications_enabled' => true,
                'payment_notifications_enabled' => true,
                'claim_notifications_enabled' => true,
                'payout_notifications_enabled' => true,
                'reminder_notifications_enabled' => true,
            ]
        );

        $preference->fill($validated);
        $preference->save();

        return response()->json([
            'message' => 'Preferencias de notificaciones actualizadas correctamente.',
            'data' => $preference->fresh(),
        ]);
    }
}