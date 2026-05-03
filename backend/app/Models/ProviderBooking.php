<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderBooking extends Model
{
    protected $fillable = [
        'provider_id',
        'provider_experience_id',
        'user_id',
        'booking_code',
        'customer_name',
        'customer_phone',
        'customer_email',
        'booking_date',
        'guests_count',
        'unit_price',
        'total_amount',
        'provider_earning',
        'status',
    ];

    protected $casts = [
        'booking_date' => 'datetime',
        'guests_count' => 'integer',
        'unit_price' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'provider_earning' => 'decimal:2',
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

    /**
     * Cliente autenticado, si aplica.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}