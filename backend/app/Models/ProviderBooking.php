<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Models\PaymentTransaction;
use App\Models\PaymentRefund;

use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Models\BookingClaim;

class ProviderBooking extends Model
{

    public const STATUS_PENDING = 'pending';
    public const STATUS_CONFIRMED = 'confirmed';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';

    public const PAYMENT_STATUS_SCHEDULED = 'scheduled';
    public const PAYMENT_STATUS_PROCESSING = 'processing';
    public const PAYMENT_STATUS_PENDING_VERIFICATION = 'pending_verification';
    public const PAYMENT_STATUS_PAID = 'paid';
    public const PAYMENT_STATUS_FAILED = 'failed';
    public const PAYMENT_STATUS_CANCELLED = 'cancelled';
    public const PAYMENT_STATUS_REFUNDED = 'refunded';
    public const PAYMENT_STATUS_PARTIALLY_REFUNDED = 'partially_refunded';

    public const CANCELLED_BY_CUSTOMER = 'customer';
    public const CANCELLED_BY_PROVIDER = 'provider';
    public const CANCELLED_BY_ADMIN = 'admin';
    public const CANCELLED_BY_SYSTEM = 'system';

    protected $fillable = [
        'provider_id',
        'provider_experience_id',
        'provider_experience_schedule_id',
        'user_id',
        'booking_code',
        'customer_name',
        'customer_phone',
        'customer_email',
        'booking_date',
        'pickup_point',
        'guests_count',
        'unit_price',
        'original_unit_price',
        'discount_percentage',
        'discount_amount',
        'total_amount',
        'provider_earning',
        'status',
        'cancelled_at',
        'cancellation_policy_type',
        'refund_amount',
        'administrative_fee_amount',
        'refund_percentage',
        'trip_reminder_sent_at',
        'customer_payment_method_id',
        'payment_status',
        'refund_status',
        'provider_payout_status',
        'charge_scheduled_at',
        'charged_at',
        'refunded_at',
        'cancelled_by',
        'cancellation_reason',
    ];

    protected $casts = [
        'booking_date' => 'datetime',
        'guests_count' => 'integer',
        'unit_price' => 'decimal:2',
        'original_unit_price' => 'decimal:2',
        'discount_percentage' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'provider_earning' => 'decimal:2',
        'cancelled_at' => 'datetime',
        'refund_amount' => 'decimal:2',
        'administrative_fee_amount' => 'decimal:2',
        'refund_percentage' => 'integer',
        'trip_reminder_sent_at' => 'datetime',
        'charge_scheduled_at' => 'datetime',
        'charged_at' => 'datetime',
        'refunded_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    /**
     * Afiliado dueño de la reserva.
     */
    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    /**
     * Experiencia reservada.
     */
    public function experience(): BelongsTo
    {
        return $this->belongsTo(ProviderExperience::class, 'provider_experience_id');
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(
            ProviderExperienceSchedule::class,
            'provider_experience_schedule_id'
        );
    }

    /**
     * Cliente autenticado, si aplica.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(
            ProviderReview::class,
            'provider_booking_id'
        );
    }

    public function conversation(): HasOne
    {
        return $this->hasOne(
            Conversation::class,
            'provider_booking_id'
        );
    }

    public function claim(): HasOne
    {
        return $this->hasOne(
            BookingClaim::class,
            'provider_booking_id'
        );
    }

    public function paymentTransactions(): HasMany
    {
        return $this->hasMany(PaymentTransaction::class, 'provider_booking_id');
    }

    public function paymentRefunds(): HasMany
    {
        return $this->hasMany(PaymentRefund::class, 'provider_booking_id');
    }

    public function legalAcceptances(): HasMany
    {
        return $this->hasMany(
            LegalAcceptance::class,
            'booking_id'
        );
    }

    public function latestPaymentTransaction()
    {
        return $this->hasOne(PaymentTransaction::class, 'provider_booking_id')->latestOfMany();
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isConfirmed(): bool
    {
        return $this->status === self::STATUS_CONFIRMED;
    }

    public function isCompleted(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }

    public function isCancelled(): bool
    {
        return $this->status === self::STATUS_CANCELLED;
    }

    public function isPaid(): bool
    {
        return $this->payment_status === self::PAYMENT_STATUS_PAID;
    }

}