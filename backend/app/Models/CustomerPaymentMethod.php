<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Tarjeta tokenizada del cliente.
 *
 * IMPORTANTE:
 * No guarda PAN completo ni CVV.
 */
class CustomerPaymentMethod extends Model
{
    use SoftDeletes;

    protected $table = 'customer_payment_methods';

    protected $fillable = [
        'user_id',
        'gateway',
        'type',
        'brand',
        'last4',
        'masked_card_number',
        'holder_name',
        'expiry_month',
        'expiry_year',
        'is_default',
        'payment_token',
        'token_expires_at',
        'gateway_response_payload',
    ];

    protected $casts = [
        'expiry_month' => 'integer',
        'expiry_year' => 'integer',
        'is_default' => 'boolean',
        'token_expires_at' => 'datetime',
        'gateway_response_payload' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function hasGatewayToken(): bool
    {
        return ! blank($this->payment_token);
    }

    public function paymentTransactions(): HasMany
    {
        return $this->hasMany(PaymentTransaction::class, 'customer_payment_method_id');
    }
}