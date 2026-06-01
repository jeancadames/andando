<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderReviewPhoto extends Model
{
    protected $fillable = [
        'provider_review_id',
        'photo_path',
        'sort_order',
    ];

    protected $casts = [
        'sort_order' => 'integer',
    ];

    protected $appends = [
        'photo_url',
    ];

    public function review(): BelongsTo
    {
        return $this->belongsTo(ProviderReview::class, 'provider_review_id');
    }

    public function getPhotoUrlAttribute(): ?string
    {
        if (! $this->photo_path) {
            return null;
        }

        return url('/api/storage/' . $this->photo_path);
    }
}