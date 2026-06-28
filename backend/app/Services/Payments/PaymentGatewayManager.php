<?php

namespace App\Services\Payments;

use App\Contracts\Payments\PaymentGatewayInterface;
use App\Services\Payments\Gateways\AzulWebServicesGateway;
use App\Services\Payments\Gateways\FakeAzulGateway;
use InvalidArgumentException;

class PaymentGatewayManager
{
    public function gateway(): PaymentGatewayInterface
    {
        return match (config('payments.gateway')) {
            'fake_azul' => app(FakeAzulGateway::class),
            'azul' => app(AzulWebServicesGateway::class),
            default => throw new InvalidArgumentException(
                'Gateway de pago no soportado: ' . config('payments.gateway')
            ),
        };
    }
}