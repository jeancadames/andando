<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserNotificationPreference extends Model
{
    protected $fillable = [
        'user_id',
        'push_enabled',
        'booking_notifications_enabled',
        'message_notifications_enabled',
        'payment_notifications_enabled',
        'claim_notifications_enabled',
        'payout_notifications_enabled',
        'reminder_notifications_enabled',
    ];

    protected $casts = [
        'push_enabled' => 'boolean',
        'booking_notifications_enabled' => 'boolean',
        'message_notifications_enabled' => 'boolean',
        'payment_notifications_enabled' => 'boolean',
        'claim_notifications_enabled' => 'boolean',
        'payout_notifications_enabled' => 'boolean',
        'reminder_notifications_enabled' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}