<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * Modelo ProviderExperience.
 *
 * Representa una experiencia turística creada por un proveedor.
 *
 * Esta entidad es utilizada por:
 * - El panel del proveedor para crear y administrar experiencias.
 * - La pantalla Explorar del cliente/visitante.
 * - El flujo de reservas.
 * - El flujo de reseñas.
 */
class ProviderExperience extends Model
{
    use SoftDeletes;

    /**
     * Campos que pueden ser asignados de forma masiva.
     *
     * Estos campos corresponden a la tabla provider_experiences.
     */
    protected $fillable = [
        'provider_id',
        'title',
        'category',
        'description',
        'duration',
        'location',
        'province',
        'experience_address',
        'experience_latitude',
        'experience_longitude',
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
        'cancellation_penalty_hours',
        'cancellation_penalty_percentage',
        'cancellation_policy_description',
        'status',
        'published_at',
        'is_active',
        'includes_transport',
    ];

    /**
     * Conversión automática de tipos.
     *
     * Laravel convertirá estos campos al tipo indicado cuando se lean
     * o escriban desde el modelo.
     */
    protected $casts = [
        'pickup_points' => 'array',
        'experience_latitude' => 'decimal:7',
        'experience_longitude' => 'decimal:7',
        'itinerary' => 'array',
        'amenities' => 'array',
        'included' => 'array',
        'not_included' => 'array',
        'requirements' => 'array',
        'price' => 'decimal:2',
        'capacity' => 'integer',
        'is_active' => 'boolean',
        'published_at' => 'datetime',
        'includes_transport' => 'boolean',
        'cancellation_penalty_hours' => 'integer',
        'cancellation_penalty_percentage' => 'integer',
    ];

    /**
     * Relación con el proveedor dueño de la experiencia.
     */
    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    /**
     * Relación con todas las fotos de la experiencia.
     *
     * Se ordenan por sort_order para mantener el orden definido
     * por el proveedor.
     */
    public function photos(): HasMany
    {
        return $this->hasMany(ProviderExperiencePhoto::class)
            ->orderBy('sort_order');
    }

    /**
     * Foto principal o portada de la experiencia.
     */
    public function coverPhoto(): HasOne
    {
        return $this->hasOne(ProviderExperiencePhoto::class)
            ->where('is_cover', true);
    }

    /**
     * Horarios disponibles asociados a la experiencia.
     */
    public function schedules(): HasMany
    {
        return $this->hasMany(ProviderExperienceSchedule::class);
    }

    /**
     * Próximo horario disponible de la experiencia.
     *
     * Se usa principalmente en la pantalla Explorar para mostrar
     * la fecha más cercana en la que el customer puede reservar.
     *
     * Criterios:
     * - starts_at debe ser igual o mayor a la fecha/hora actual.
     * - status debe estar disponible.
     * - se ordena por starts_at ascendente para obtener el más cercano.
     */
    public function nextAvailableSchedule(): HasOne
    {
        return $this->hasOne(ProviderExperienceSchedule::class)
            ->where('starts_at', '>=', now())
            ->where('status', 'available')
            ->orderBy('starts_at');
    }

    /**
     * Reservas asociadas a esta experiencia.
     */
    public function bookings(): HasMany
    {
        return $this->hasMany(ProviderBooking::class);
    }

    /**
     * Reseñas asociadas a esta experiencia.
     */
    public function reviews(): HasMany
    {
        return $this->hasMany(
            ProviderReview::class,
            'provider_experience_id'
        );
    }

    public function conversations(): HasMany
    {
        return $this->hasMany(
            Conversation::class,
            'provider_experience_id'
        );
    }

    public function legalAcceptances(): HasMany
    {
        return $this->hasMany(
            LegalAcceptance::class,
            'experience_id'
        );
    }

    /**
     * Puntos de recogida geolocalizados para mostrar en mapa.
     *
     * Se usa mapPickupPoints para evitar conflicto con el campo JSON
     * pickup_points que ya existe en el modelo.
     */
    public function mapPickupPoints(): HasMany
    {
        return $this->hasMany(
            ProviderExperiencePickupPoint::class,
            'provider_experience_id'
        )
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id');
    }
}