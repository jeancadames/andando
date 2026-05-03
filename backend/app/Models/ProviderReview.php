<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderReview extends Model
{
    protected $fillable = [
        'provider_id',
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

    /**
     * Afiliado evaluado.
     */
    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    /**
     * Reserva asociada al review.
     */
    public function booking(): BelongsTo
    {
        return $this->belongsTo(ProviderBooking::class, 'provider_booking_id');
    }

    /**
     * Cliente que dejó el review.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}