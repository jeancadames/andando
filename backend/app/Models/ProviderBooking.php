<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Models\BookingClaim;

class ProviderBooking extends Model
{
    protected $fillable = [
        'provider_id',
        'provider_experience_id',
        'provider_experience_schedule_id',
        'user_id',
        'booking_code',
        'customer_name',
        'customer_phone',
        'customer_email',
        'booking_date',
        'pickup_point',
        'guests_count',
        'unit_price',
        'total_amount',
        'provider_earning',
        'status',
        'cancelled_at',
        'cancellation_policy_type',
        'refund_amount',
        'administrative_fee_amount',
        'refund_percentage',
    ];

    protected $casts = [
        'booking_date' => 'datetime',
        'guests_count' => 'integer',
        'unit_price' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'provider_earning' => 'decimal:2',
        'cancelled_at' => 'datetime',
        'refund_amount' => 'decimal:2',
        'administrative_fee_amount' => 'decimal:2',
        'refund_percentage' => 'integer',
    ];

    /**
     * Afiliado dueño de la reserva.
     */
    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    /**
     * Experiencia reservada.
     */
    public function experience(): BelongsTo
    {
        return $this->belongsTo(ProviderExperience::class, 'provider_experience_id');
    }

    public function schedule(): BelongsTo
{
    return $this->belongsTo(
        ProviderExperienceSchedule::class,
        'provider_experience_schedule_id'
    );
}

    /**
     * Cliente autenticado, si aplica.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(
            ProviderReview::class,
            'provider_booking_id'
        );
    }

    public function conversation(): HasOne
    {
        return $this->hasOne(
            Conversation::class,
            'provider_booking_id'
        );
    }

    public function claim(): HasOne
    {
        return $this->hasOne(
            BookingClaim::class,
            'provider_booking_id'
        );
    }
}