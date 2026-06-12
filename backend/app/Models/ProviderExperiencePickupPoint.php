<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Modelo ProviderExperiencePickupPoint.
 *
 * Representa un punto de recogida geolocalizado de una experiencia.
 * Estos puntos se mostrarán en el mapa del detalle de experiencia.
 */
class ProviderExperiencePickupPoint extends Model
{
    protected $table = 'provider_experience_pickup_points';

    protected $fillable = [
        'provider_experience_id',
        'name',
        'address',
        'latitude',
        'longitude',
        'instructions',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'sort_order' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Experiencia a la que pertenece este punto de recogida.
     */
    public function experience(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperience::class,
            'provider_experience_id'
        );
    }
}