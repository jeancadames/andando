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

    /**
     * Conversión automática de tipos.
     *
     * Laravel convertirá estos campos al tipo indicado cuando se lean
     * o escriban desde el modelo.
     */
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
}