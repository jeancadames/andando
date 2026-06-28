<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PaymentTransaction extends Model
{

    public const TYPE_CHARGE = 'charge';

    public const STATUS_SCHEDULED = 'scheduled';
    public const STATUS_PROCESSING = 'processing';
    public const STATUS_PAID = 'paid';
    public const STATUS_FAILED = 'failed';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_REFUNDED = 'refunded';
    public const STATUS_PARTIALLY_REFUNDED = 'partially_refunded';

    protected $fillable = [
        'provider_booking_id',
        'provider_experience_schedule_id',
        'user_id',
        'provider_id',
        'customer_payment_method_id',
        'gateway',
        'environment',
        'type',
        'status',
        'amount',
        'currency',
        'itbis_amount',
        'commission_rate',
        'andando_commission_amount',
        'provider_amount',
        'charge_scheduled_at',
        'processed_at',
        'gateway_transaction_id',
        'gateway_order_id',
        'gateway_authorization_code',
        'gateway_rrn',
        'gateway_response_code',
        'gateway_iso_code',
        'gateway_response_message',
        'gateway_error_description',
        'raw_request',
        'raw_response',
        'idempotency_key',
        'failure_reason',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'itbis_amount' => 'decimal:2',
        'commission_rate' => 'decimal:4',
        'andando_commission_amount' => 'decimal:2',
        'provider_amount' => 'decimal:2',
        'charge_scheduled_at' => 'datetime',
        'processed_at' => 'datetime',
        'raw_request' => 'array',
        'raw_response' => 'array',
    ];

    public function booking(): BelongsTo
    {
        return $this->belongsTo(ProviderBooking::class, 'provider_booking_id');
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(ProviderExperienceSchedule::class, 'provider_experience_schedule_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(CustomerPaymentMethod::class, 'customer_payment_method_id');
    }

    public function refunds(): HasMany
    {
        return $this->hasMany(PaymentRefund::class);
    }

        public function isScheduled(): bool
    {
        return $this->status === self::STATUS_SCHEDULED;
    }

    public function isProcessing(): bool
    {
        return $this->status === self::STATUS_PROCESSING;
    }

    public function isPaid(): bool
    {
        return $this->status === self::STATUS_PAID;
    }

    public function isFailed(): bool
    {
        return $this->status === self::STATUS_FAILED;
    }

    public function isRefunded(): bool
    {
        return $this->status === self::STATUS_REFUNDED;
    }

    public function isPartiallyRefunded(): bool
    {
        return $this->status === self::STATUS_PARTIALLY_REFUNDED;
    }
}