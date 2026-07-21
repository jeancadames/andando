<?php

namespace App\Models;

// AndanDO Provider Commissions Module

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderCommissionChange extends Model
{
    public const SOURCE_APPROVAL = 'approval';
    public const SOURCE_ADMIN_UPDATE = 'admin_update';

    protected $fillable = [
        'provider_id',
        'changed_by_user_id',
        'old_rate',
        'new_rate',
        'source',
    ];

    protected $casts = [
        'old_rate' => 'decimal:4',
        'new_rate' => 'decimal:4',
    ];

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by_user_id');
    }
}
