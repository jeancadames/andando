<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PaymentRefund extends Model
{

    public const STATUS_PENDING = 'pending';
    public const STATUS_PROCESSING = 'processing';
    public const STATUS_SUCCEEDED = 'succeeded';
    public const STATUS_FAILED = 'failed';
    public const STATUS_PENDING_VERIFICATION = 'pending_verification';

    public const REASON_CUSTOMER_POLICY = 'customer_policy';
    public const REASON_PROVIDER_CANCELLED = 'provider_cancelled';
    public const REASON_WEATHER = 'weather';
    public const REASON_FORCE_MAJEURE = 'force_majeure';
    public const REASON_ADMIN = 'admin';
    public const REASON_CLAIM = 'claim';


    protected $fillable = [
        'payment_transaction_id',
        'provider_booking_id',
        'user_id',
        'gateway',
        'environment',
        'status',
        'reason',
        'amount',
        'currency',
        'refund_percent',
        'retained_amount',
        'gateway_refund_id',
        'gateway_response_code',
        'gateway_iso_code',
        'gateway_response_message',
        'gateway_error_description',
        'raw_request',
        'raw_response',
        'processed_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'refund_percent' => 'decimal:2',
        'retained_amount' => 'decimal:2',
        'raw_request' => 'array',
        'raw_response' => 'array',
        'processed_at' => 'datetime',
    ];

    public function transaction(): BelongsTo
    {
        return $this->belongsTo(PaymentTransaction::class, 'payment_transaction_id');
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(ProviderBooking::class, 'provider_booking_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** AndanDO Admin Payments Module */
    public function attempts(): HasMany
    {
        return $this->hasMany(PaymentRefundAttempt::class)->orderBy('attempt_number');
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isProcessing(): bool
    {
        return $this->status === self::STATUS_PROCESSING;
    }

    public function isSucceeded(): bool
    {
        return $this->status === self::STATUS_SUCCEEDED;
    }

    public function isFailed(): bool
    {
        return $this->status === self::STATUS_FAILED;
    }

    public function isPendingVerification(): bool
    {
        return $this->status === self::STATUS_PENDING_VERIFICATION;
    }
}