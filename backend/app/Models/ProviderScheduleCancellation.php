<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderScheduleCancellation extends Model
{
    protected $fillable = [
        'provider_id',
        'provider_experience_id',
        'provider_experience_schedule_id',
        'cancelled_by_user_id',
        'reason_type',
        'reason_description',
        'bookings_cancelled_count',
        'scheduled_start_at',
        'policy_deadline_at',
        'cancellation_penalty_hours',
        'was_within_policy',
        'cancelled_at',
    ];

    protected $casts = [
        'bookings_cancelled_count' => 'integer',
        'scheduled_start_at' => 'datetime',
        'policy_deadline_at' => 'datetime',
        'cancellation_penalty_hours' => 'integer',
        'was_within_policy' => 'boolean',
        'cancelled_at' => 'datetime',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function experience(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperience::class,
            'provider_experience_id'
        );
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperienceSchedule::class,
            'provider_experience_schedule_id'
        );
    }

    public function cancelledByUser(): BelongsTo
    {
        return $this->belongsTo(
            User::class,
            'cancelled_by_user_id'
        );
    }
}