<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LegalAcceptance extends Model
{
    protected $fillable = [
        'legal_document_id',
        'user_id',
        'provider_id',
        'booking_id',
        'experience_id',
        'schedule_id',
        'accepted_at',
        'document_checksum',
        'ip_address',
        'user_agent',
        'platform',
        'app_version',
        'locale',
        'metadata',
    ];

    protected $casts = [
        'accepted_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function legalDocument(): BelongsTo
    {
        return $this->belongsTo(LegalDocument::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(
            ProviderBooking::class,
            'booking_id'
        );
    }

    public function experience(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperience::class,
            'experience_id'
        );
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperienceSchedule::class,
            'schedule_id'
        );
    }
}