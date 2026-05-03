<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProviderExperienceScheduleSeries extends Model
{
    use SoftDeletes;

    protected $table = 'provider_experience_schedule_series';

    protected $fillable = [
        'provider_id',
        'provider_experience_id',
        'starts_on',
        'ends_on',
        'departure_time',
        'timezone',
        'frequency',
        'days_of_week',
        'status',
    ];

    protected $casts = [
        'starts_on' => 'date',
        'ends_on' => 'date',
        'days_of_week' => 'array',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function experience(): BelongsTo
    {
        return $this->belongsTo(ProviderExperience::class, 'provider_experience_id');
    }

    public function schedules(): HasMany
    {
        return $this->hasMany(ProviderExperienceSchedule::class, 'series_id');
    }
}