<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ProviderExperience extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'provider_id',
        'title',
        'category',
        'description',
        'duration',
        'location',
        'province',
        'start_location',
        'pickup_points',
        'price',
        'currency',
        'capacity',
        'itinerary',
        'amenities',
        'included',
        'not_included',
        'requirements',
        'cancellation_policy',
        'status',
        'published_at',
        'is_active',
    ];

    protected $casts = [
        'pickup_points' => 'array',
        'itinerary' => 'array',
        'amenities' => 'array',
        'included' => 'array',
        'not_included' => 'array',
        'requirements' => 'array',
        'price' => 'decimal:2',
        'capacity' => 'integer',
        'is_active' => 'boolean',
        'published_at' => 'datetime',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(ProviderExperiencePhoto::class)
            ->orderBy('sort_order');
    }

    public function coverPhoto(): HasOne
    {
        return $this->hasOne(ProviderExperiencePhoto::class)
            ->where('is_cover', true);
    }

    public function schedules(): HasMany
    {
        return $this->hasMany(ProviderExperienceSchedule::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(ProviderBooking::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(ProviderReview::class, 'provider_id', 'provider_id');
    }
}