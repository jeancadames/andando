<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BookingClaim extends Model
{
    protected $fillable = [
        'provider_booking_id',
        'provider_id',
        'user_id',
        'reason',
        'description',
        'status',
        'provider_response',
        'provider_replied_at',
        'resolved_at',
    ];

    protected $casts = [
        'provider_replied_at' => 'datetime',
        'resolved_at' => 'datetime',
    ];

    public function booking(): BelongsTo
    {
        return $this->belongsTo(
            ProviderBooking::class,
            'provider_booking_id'
        );
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}