<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProviderExperienceSchedule extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'provider_id',
        'series_id',
        'provider_experience_id',
        'starts_at',
        'ends_at',
        'timezone',
        'capacity',
        'price',
        'currency',
        'status',
        'notes',
        'cancellation_reason',
    ];

    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'capacity' => 'integer',
        'price' => 'decimal:2',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function experience(): BelongsTo
    {
        return $this->belongsTo(ProviderExperience::class, 'provider_experience_id');
    }

    public function series(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperienceScheduleSeries::class,
            'series_id'
        );
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(ProviderBooking::class, 'provider_experience_schedule_id');
    }
}