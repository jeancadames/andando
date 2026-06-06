<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConversationMessage extends Model
{
    protected $fillable = [
        'conversation_id',
        'sender_user_id',
        'sender_type',
        'message',
        'attachment_path',
        'attachment_type',
        'attachment_original_name',
        'attachment_mime_type',
        'attachment_size_bytes',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
        'attachment_size_bytes' => 'integer',
    ];

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_user_id');
    }

    public function hasAttachment(): bool
    {
        return filled($this->attachment_path);
    }

    public function getAttachmentUrlAttribute(): ?string
    {
        if (! $this->attachment_path) {
            return null;
        }

        return url('/api/public-files/' . ltrim($this->attachment_path, '/'));
    }
}