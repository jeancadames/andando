<?php

namespace App\Models;

// AndanDO Admin Payments Module

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentRefundAttempt extends Model
{
    public const TRIGGER_AUTOMATIC = 'automatic';
    public const TRIGGER_MANUAL = 'manual';

    protected $fillable = [
        'payment_refund_id',
        'attempt_number',
        'trigger',
        'initiated_by_user_id',
        'status',
        'gateway_refund_id',
        'gateway_response_code',
        'gateway_iso_code',
        'gateway_response_message',
        'gateway_error_description',
        'raw_request',
        'raw_response',
        'started_at',
        'completed_at',
    ];

    protected $casts = [
        'attempt_number' => 'integer',
        'raw_request' => 'array',
        'raw_response' => 'array',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function refund(): BelongsTo
    {
        return $this->belongsTo(PaymentRefund::class, 'payment_refund_id');
    }

    public function initiatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'initiated_by_user_id');
    }
}
