<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderReview extends Model
{
    protected $fillable = [
        'provider_id',
        'provider_experience_id',
        'provider_booking_id',
        'user_id',
        'rating',
        'comment',
        'is_visible',
    ];

    protected $casts = [
        'rating' => 'integer',
        'is_visible' => 'boolean',
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

    public function booking(): BelongsTo
    {
        return $this->belongsTo(
            ProviderBooking::class,
            'provider_booking_id'
        );
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(ProviderReviewPhoto::class)
            ->orderBy('sort_order');
    }
}