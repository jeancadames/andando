<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/// Documento subido por el proveedor para validación.
class ProviderDocument extends Model
{
    protected $fillable = [
        'provider_id',
        'provider_verification_request_id',
        'type',
        'status',
        'disk',
        'path',
        'original_name',
        'mime_type',
        'size_bytes',
        'reviewed_at',
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function verificationRequest(): BelongsTo
    {
        return $this->belongsTo(ProviderVerificationRequest::class);
    }
}