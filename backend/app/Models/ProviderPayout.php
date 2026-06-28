<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderPayout extends Model
{
    public const STATUS_NOT_READY = 'not_ready';
    public const STATUS_SCHEDULED = 'scheduled';
    public const STATUS_ON_HOLD = 'on_hold';
    public const STATUS_READY_TO_PAY = 'ready_to_pay';
    public const STATUS_PAID = 'paid';
    public const STATUS_FAILED = 'failed';
    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'provider_id',
        'provider_experience_schedule_id',
        'status',
        'scheduled_release_at',
        'released_at',
        'held_at',
        'hold_reason',
        'held_by_claim_id',
        'released_from_hold_at',
        'gross_amount',
        'commission_rate',
        'commission_amount',
        'net_amount',
        'currency',
        'payout_method',
        'external_reference',
        'failure_reason',
        'notes',
    ];

    protected $casts = [
        'scheduled_release_at' => 'datetime',
        'released_at' => 'datetime',
        'held_at' => 'datetime',
        'released_from_hold_at' => 'datetime',
        'gross_amount' => 'decimal:2',
        'commission_rate' => 'decimal:4',
        'commission_amount' => 'decimal:2',
        'net_amount' => 'decimal:2',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(ProviderExperienceSchedule::class, 'provider_experience_schedule_id');
    }

    public function heldByClaim(): BelongsTo
    {
        return $this->belongsTo(BookingClaim::class, 'held_by_claim_id');
    }

    public function isOnHold(): bool
    {
        return $this->status === self::STATUS_ON_HOLD;
    }

    public function isReadyToPay(): bool
    {
        return $this->status === self::STATUS_READY_TO_PAY;
    }

    public function isPaid(): bool
    {
        return $this->status === self::STATUS_PAID;
    }
}