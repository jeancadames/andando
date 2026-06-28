<?php

namespace App\Contracts\Payments;

use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;

interface PaymentGatewayInterface
{
    /**
     * Procesa un cobro contra la pasarela.
     */
    public function charge(PaymentTransaction $transaction): array;

    /**
     * Procesa un reembolso contra la pasarela.
     */
    public function refund(PaymentRefund $refund): array;

    /**
     * Verifica una transacción en la pasarela.
     */
    public function verify(PaymentTransaction $transaction): array;
}