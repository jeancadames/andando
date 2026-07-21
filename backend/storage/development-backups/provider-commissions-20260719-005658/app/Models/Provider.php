<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/// Modelo principal del proveedor.
class Provider extends Model
{
    protected $fillable = [
        'user_id',
        'provider_business_type_id',
        'business_name',
        'rnc',
        'address',
        'city',
        'province',
        'status',
        'commission_rate',
        'rejection_reason',
        'approved_at',
        'rejected_at',
        'suspended_at',
    ];

    protected $casts = [
        'commission_rate' => 'decimal:4',
        'approved_at' => 'datetime',
        'rejected_at' => 'datetime',
        'suspended_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function businessType(): BelongsTo
    {
        return $this->belongsTo(ProviderBusinessType::class, 'provider_business_type_id');
    }

    public function verificationRequests(): HasMany
    {
        return $this->hasMany(ProviderVerificationRequest::class);
    }

    public function documents(): HasMany
    {
        return $this->hasMany(ProviderDocument::class);
    }
    
    public function experiences(): HasMany
    {
        return $this->hasMany(ProviderExperience::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(ProviderBooking::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(ProviderReview::class);
    }

    public function conversations(): HasMany
    {
        return $this->hasMany(Conversation::class);
    }

    public function experienceSchedules()
    {
        return $this->hasMany(ProviderExperienceSchedule::class);
    }

    public function legalAcceptances(): HasMany
    {
        return $this->hasMany(LegalAcceptance::class);
    }

    /** AndanDO Provider Commissions Module */
    public function commissionRate(): float
    {
        $rate = $this->commission_rate;

        if ($rate === null) {
            $rate = config('payments.rules.andando_commission_rate', 0.15);
        }

        return max(0, min(1, (float) $rate));
    }

    public function commissionChanges(): HasMany
    {
        return $this->hasMany(ProviderCommissionChange::class);
    }

    public function latestCommissionChange(): HasOne
    {
        return $this->hasOne(ProviderCommissionChange::class)->latestOfMany();
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function isRejected(): bool
    {
        return $this->status === 'rejected';
    }
}
