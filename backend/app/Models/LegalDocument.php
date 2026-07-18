<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LegalDocument extends Model
{
    public const CHANGE_LEVEL_MINOR = 'minor';
    public const CHANGE_LEVEL_MATERIAL = 'material';

    protected $fillable = [
        'type',
        'audience',
        'version',
        'title',
        'content',
        'summary',
        'content_format',
        'effective_at',
        'published_at',
        'requires_acceptance',
        'change_level',
        'is_active',
        'checksum',
        'supersedes_id',
    ];

    protected $casts = [
        'effective_at' => 'datetime',
        'published_at' => 'datetime',
        'requires_acceptance' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function supersedes(): BelongsTo
    {
        return $this->belongsTo(
            LegalDocument::class,
            'supersedes_id'
        );
    }

    public function subsequentVersions(): HasMany
    {
        return $this->hasMany(
            LegalDocument::class,
            'supersedes_id'
        );
    }

    public function acceptances(): HasMany
    {
        return $this->hasMany(LegalAcceptance::class);
    }

    public function isMaterialChange(): bool
    {
        return $this->change_level === self::CHANGE_LEVEL_MATERIAL;
    }

    public function isCurrentlyEffective(): bool
    {
        return $this->is_active
            && $this->effective_at->lessThanOrEqualTo(now());
    }

    public static function calculateChecksum(string $content): string
    {
        return hash('sha256', $content);
    }
}