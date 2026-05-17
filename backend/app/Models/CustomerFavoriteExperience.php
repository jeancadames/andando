<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerFavoriteExperience extends Model
{
    protected $fillable = [
        'user_id',
        'provider_experience_id',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function experience(): BelongsTo
    {
        return $this->belongsTo(ProviderExperience::class, 'provider_experience_id');
    }
}