<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderExperiencePhoto extends Model
{
    protected $fillable = [
        'provider_experience_id',
        'path',
        'original_name',
        'mime_type',
        'size_bytes',
        'sort_order',
        'is_cover',
    ];

    protected $casts = [
        'is_cover' => 'boolean',
        'sort_order' => 'integer',
        'size_bytes' => 'integer',
    ];

    public function experience(): BelongsTo
    {
        return $this->belongsTo(ProviderExperience::class, 'provider_experience_id');
    }
}