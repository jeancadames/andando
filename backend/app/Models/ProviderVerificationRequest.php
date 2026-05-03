<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/// Solicitud de verificación enviada por un proveedor.
class ProviderVerificationRequest extends Model
{
    protected $fillable = [
        'provider_id',
        'status',
        'submitted_at',
        'reviewed_by',
        'reviewed_at',
        'rejection_reason',
        'terms_accepted',
        'terms_accepted_at',
        'terms_version',
        'privacy_accepted',
        'privacy_accepted_at',
        'privacy_version',
    ];

    protected $casts = [
        'submitted_at' => 'datetime',
        'reviewed_at' => 'datetime',
        'terms_accepted' => 'boolean',
        'terms_accepted_at' => 'datetime',
        'privacy_accepted' => 'boolean',
        'privacy_accepted_at' => 'datetime',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function documents(): HasMany
    {
        return $this->hasMany(ProviderDocument::class);
    }
}