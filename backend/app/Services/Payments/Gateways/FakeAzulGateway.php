<?php

namespace App\Services\Payments\Gateways;

use App\Contracts\Payments\PaymentGatewayInterface;
use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;
use Illuminate\Support\Str;

class FakeAzulGateway implements PaymentGatewayInterface
{
    public function charge(PaymentTransaction $transaction): array
    {
        return match (config('payments.fake_azul.force_result')) {
            'declined' => $this->declined('05', 'DECLINADA'),
            'insufficient_funds' => $this->declined('51', 'INSUF FONDOS'),
            'invalid_token' => $this->error('DataVault TokenId does not exist.'),
            'timeout' => $this->error('The operation has timed out.'),
            default => $this->approved(),
        };
    }

    public function refund(PaymentRefund $refund): array
    {
        if (config('payments.fake_azul.force_result') === 'refund_failed') {
            return $this->error('Original transaction is invalid or has already been returned.');
        }

        return $this->approved([
            'AzulOrderId' => 'RF' . Str::random(6),
        ]);
    }

    public function verify(PaymentTransaction $transaction): array
    {
        return $this->approved([
            'Found' => true,
        ]);
    }

    private function approved(array $extra = []): array
    {
        return array_merge([
            'success' => true,
            'ResponseCode' => 'ISO8583',
            'IsoCode' => '00',
            'ResponseMessage' => 'APROBADA',
            'AuthorizationCode' => config('payments.fake_azul.fake_auth_code'),
            'AzulOrderId' => config('payments.fake_azul.fake_azul_order_id'),
            'RRN' => config('payments.fake_azul.fake_rrn'),
            'DateTime' => now()->format('YmdHis'),
        ], $extra);
    }

    private function declined(string $isoCode, string $message): array
    {
        return [
            'success' => false,
            'ResponseCode' => 'ISO8583',
            'IsoCode' => $isoCode,
            'ResponseMessage' => $message,
            'AuthorizationCode' => '',
            'AzulOrderId' => '',
            'RRN' => '',
            'DateTime' => now()->format('YmdHis'),
        ];
    }

    private function error(string $description): array
    {
        return [
            'success' => false,
            'ResponseCode' => 'Error',
            'IsoCode' => '',
            'ResponseMessage' => '',
            'ErrorDescription' => $description,
            'AuthorizationCode' => '',
            'AzulOrderId' => '',
            'RRN' => '',
            'DateTime' => now()->format('YmdHis'),
        ];
    }
}