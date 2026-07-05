<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * Modelo ProviderExperienceSchedule.
 *
 * Representa una fecha y horario disponible para realizar una experiencia.
 *
 * Una experiencia puede tener varios horarios disponibles.
 * Cada horario puede tener su propia capacidad, precio, moneda y estado.
 */
class ProviderExperienceSchedule extends Model
{
    use SoftDeletes;

    /**
     * Campos que pueden ser asignados de forma masiva.
     */
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
        'provider_reminder_sent_at',
    ];

    /**
     * Conversión automática de tipos.
     */
    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'capacity' => 'integer',
        'price' => 'decimal:2',
        'provider_reminder_sent_at' => 'datetime',
    ];

    /**
     * Proveedor dueño del horario.
     */
    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    /**
     * Experiencia a la que pertenece este horario.
     */
    public function experience(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperience::class,
            'provider_experience_id'
        );
    }

    /**
     * Serie de horarios a la que pertenece este horario.
     *
     * Se usa cuando los horarios fueron generados de forma recurrente.
     */
    public function series(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperienceScheduleSeries::class,
            'series_id'
        );
    }

    /**
     * Reservas asociadas a este horario específico.
     */
    public function bookings(): HasMany
    {
        return $this->hasMany(
            ProviderBooking::class,
            'provider_experience_schedule_id'
        );
    }

    public function paymentTransactions(): HasMany
    {
        return $this->hasMany(
            PaymentTransaction::class,
            'provider_experience_schedule_id'
        );
    }

    public function providerPayout(): HasOne
    {
        return $this->hasOne(
            ProviderPayout::class,
            'provider_experience_schedule_id'
        );
    }

}