<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentMethodTokenizationRequest extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_DECLINED = 'declined';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_FAILED = 'failed';

    protected $fillable = [
        'user_id',
        'customer_payment_method_id',
        'gateway',
        'environment',
        'order_number',
        'status',
        'azul_order_id',
        'authorization_code',
        'rrn',
        'datavault_token',
        'datavault_brand',
        'datavault_expiration',
        'masked_card_number',
        'response_code',
        'iso_code',
        'response_message',
        'error_description',
        'request_payload',
        'response_payload',
        'approved_at',
        'declined_at',
        'cancelled_at',
    ];

    protected $casts = [
        'request_payload' => 'array',
        'response_payload' => 'array',
        'approved_at' => 'datetime',
        'declined_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(CustomerPaymentMethod::class, 'customer_payment_method_id');
    }
}