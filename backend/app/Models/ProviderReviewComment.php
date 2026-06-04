<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderReviewComment extends Model
{
    /**
     * Campos que se pueden asignar masivamente.
     */
    protected $fillable = [
        'provider_review_id',
        'user_id',
        'comment',
        'is_visible',
    ];

    /**
     * Conversión automática de tipos.
     */
    protected $casts = [
        'is_visible' => 'boolean',
    ];

    /**
     * Reseña a la que pertenece este comentario.
     */
    public function review(): BelongsTo
    {
        return $this->belongsTo(
            ProviderReview::class,
            'provider_review_id'
        );
    }

    /**
     * Usuario que escribió el comentario.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}