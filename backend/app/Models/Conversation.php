<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    protected $fillable = [
        'customer_user_id',
        'provider_id',
        'provider_experience_id',
        'provider_booking_id',
        'status',
        'closed_reason',
        'closed_at',
        'last_message',
        'last_message_at',
        'customer_unread_count',
        'provider_unread_count',
    ];

    protected $casts = [
        'last_message_at' => 'datetime',
        'closed_at' => 'datetime',
        'customer_unread_count' => 'integer',
        'provider_unread_count' => 'integer',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_user_id');
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function experience(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperience::class,
            'provider_experience_id'
        );
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(
            ProviderBooking::class,
            'provider_booking_id'
        );
    }

    public function messages(): HasMany
    {
        return $this->hasMany(ConversationMessage::class);
    }

    public function isOpen(): bool
    {
        return $this->status === 'open';
    }

    public function isClosed(): bool
    {
        return $this->status === 'closed';
    }

    public function shouldAutoClose(): bool
    {
        if ($this->status !== 'open') {
            return false;
        }

        $referenceDate = $this->last_message_at ?? $this->created_at;

        if (! $referenceDate) {
            return false;
        }

        return $referenceDate->lte(
            now()->subHours(config('chat.auto_close_hours', 72))
        );
    }

    public function closeByInactivity(): void
    {
        $this->update([
            'status' => 'closed',
            'closed_reason' => 'inactive',
            'closed_at' => now(),
        ]);
    }

    public function reopen(): void
    {
        $this->update([
            'status' => 'open',
            'closed_reason' => null,
            'closed_at' => null,
        ]);
    }
}