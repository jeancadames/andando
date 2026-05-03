<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/// Modelo del catálogo de tipos de negocio.
class ProviderBusinessType extends Model
{
    protected $fillable = [
        'slug',
        'name',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function providers(): HasMany
    {
        return $this->hasMany(Provider::class);
    }
}