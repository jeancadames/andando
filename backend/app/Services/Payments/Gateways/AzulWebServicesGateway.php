<?php

namespace App\Services\Payments\Gateways;

use App\Contracts\Payments\PaymentGatewayInterface;
use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;

class AzulWebServicesGateway implements PaymentGatewayInterface
{
    public function charge(PaymentTransaction $transaction): array
    {
        throw new \RuntimeException('Azul WebServices real todavía no está habilitado.');
    }

    public function refund(PaymentRefund $refund): array
    {
        throw new \RuntimeException('Azul WebServices real todavía no está habilitado.');
    }

    public function verify(PaymentTransaction $transaction): array
    {
        throw new \RuntimeException('Azul WebServices real todavía no está habilitado.');
    }
}