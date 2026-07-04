<?php

namespace App\Services\Payments\Gateways;

use App\Contracts\Payments\PaymentGatewayInterface;
use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;
use App\Services\Payments\Azul\AzulClient;
use RuntimeException;

class AzulWebServicesGateway implements PaymentGatewayInterface
{
    public function __construct(
        private readonly AzulClient $client,
    ) {}

    public function charge(PaymentTransaction $transaction): array
    {
        $transaction->loadMissing('paymentMethod');

        $paymentMethod = $transaction->paymentMethod;

        if (! $paymentMethod || blank($paymentMethod->payment_token)) {
            throw new RuntimeException('La transacción no tiene método de pago tokenizado.');
        }

        $payload = [
            'Channel' => config('azul.channel'),
            'Store' => config('azul.merchant_id'),
            'CardNumber' => '',
            'Expiration' => '',
            'PosInputMode' => config('azul.pos_input_mode'),
            'TrxType' => 'Sale',
            'Amount' => $this->formatAmount($transaction->amount),
            'Itbis' => $this->formatAmount($transaction->itbis_amount ?? 0),
            'CurrencyPosCode' => config('azul.currency_pos_code'),
            'Payments' => config('azul.payments'),
            'Plan' => config('azul.plan'),
            'AcquirerRefData' => config('azul.acquirer_ref_data'),
            'CustomerServicePhone' => config('azul.customer_service_phone', ''),
            'OrderNumber' => '',
            'ECommerceUrl' => config('azul.ecommerce_url', ''),
            'CustomOrderId' => $this->customOrderId($transaction),
            'DataVaultToken' => $paymentMethod->payment_token,
            'SaveToDataVault' => '0',
            'AltMerchantName' => config('azul.alt_merchant_name', ''),
        ];

        if (! blank(config('azul.force_no_3ds'))) {
            $payload['ForceNo3DS'] = (string) config('azul.force_no_3ds');
        }

        $response = $this->client->post('', $payload);

        return $this->mapPaymentResponse($response, $payload);
    }

    public function refund(PaymentRefund $refund): array
    {
        $refund->loadMissing('transaction');

        $transaction = $refund->transaction;

        if (! $transaction) {
            throw new RuntimeException('La devolución no tiene transacción original asociada.');
        }

        if (blank($transaction->gateway_order_id)) {
            throw new RuntimeException('La transacción original no tiene AzulOrderId para procesar devolución.');
        }

        $payload = [
            'Channel' => config('azul.channel'),
            'Store' => config('azul.merchant_id'),
            'PosInputMode' => config('azul.pos_input_mode'),
            'TrxType' => 'Refund',
            'Amount' => $this->formatAmount($refund->amount),
            'Itbis' => $this->refundItbisAmount($refund, $transaction),
            'CurrencyPosCode' => config('azul.currency_pos_code'),
            'Payments' => config('azul.payments'),
            'Plan' => config('azul.plan'),
            'OriginalDate' => $this->originalDate($transaction),
            'OriginalTrxTicketNr' => (string) data_get($transaction->raw_response, 'Ticket', ''),
            'AcquirerRefData' => '',
            'RRN' => $transaction->gateway_rrn,
            'AzulOrderId' => $transaction->gateway_order_id,
            'CustomerServicePhone' => config('azul.customer_service_phone', ''),
            'OrderNumber' => '',
            'ECommerceUrl' => config('azul.ecommerce_url', ''),
            'CustomOrderId' => $this->refundCustomOrderId($refund),
            'DataVaultToken' => '',
            'SaveToDataVault' => '0',
            'AltMerchantName' => config('azul.alt_merchant_name', ''),
        ];

        $response = $this->client->post('', $payload);

        return $this->mapPaymentResponse($response, $payload);
    }

    public function verify(PaymentTransaction $transaction): array
    {
        $response = $this->client->post('VerifyPayment', [
            'Channel' => config('azul.channel'),
            'Store' => config('azul.merchant_id'),
            'CustomOrderId' => $this->customOrderId($transaction),
        ]);

        return $this->client->sanitizeForStorage($response);
    }

    private function mapPaymentResponse(array $response, ?array $requestPayload = null): array
    {
        $responseCode = strtoupper((string) ($response['ResponseCode'] ?? ''));
        $isoCode = (string) ($response['IsoCode'] ?? '');
        $message = strtoupper((string) ($response['ResponseMessage'] ?? ''));

        $success = $responseCode === 'ISO8583'
            && $isoCode === '00'
            && $message === 'APROBADA';

        $mapped = [
            'success' => $success,
            'ResponseCode' => $response['ResponseCode'] ?? null,
            'IsoCode' => $response['IsoCode'] ?? null,
            'ResponseMessage' => $response['ResponseMessage'] ?? null,
            'ErrorDescription' => $response['ErrorDescription'] ?? null,
            'AuthorizationCode' => $response['AuthorizationCode'] ?? null,
            'AzulOrderId' => $response['AzulOrderId'] ?? null,
            'RRN' => $response['RRN'] ?? null,
            'DateTime' => $response['DateTime'] ?? null,
            'Ticket' => $response['Ticket'] ?? null,
            'CustomOrderId' => $response['CustomOrderId'] ?? null,
            'raw_response' => $this->client->sanitizeForStorage($response),
        ];

        if ($requestPayload !== null) {
            $mapped['raw_request'] = $this->client->sanitizeForStorage($requestPayload);
        }

        return $mapped;
    }

    private function formatAmount(mixed $amount): string
    {
        $minorUnits = (int) round(((float) $amount) * 100);

        if ($minorUnits <= 0) {
            return '000';
        }

        return (string) $minorUnits;
    }

    private function refundItbisAmount(PaymentRefund $refund, PaymentTransaction $transaction): string
    {
        $originalItbis = (float) ($transaction->itbis_amount ?? 0);
        $originalAmount = (float) ($transaction->amount ?? 0);
        $refundAmount = (float) ($refund->amount ?? 0);

        if ($originalItbis <= 0 || $originalAmount <= 0 || $refundAmount <= 0) {
            return '000';
        }

        $proportionalItbis = $originalItbis * ($refundAmount / $originalAmount);

        return $this->formatAmount($proportionalItbis);
    }

    private function originalDate(PaymentTransaction $transaction): string
    {
        if ($transaction->processed_at) {
            return $transaction->processed_at->format('Ymd');
        }

        $dateTime = data_get($transaction->raw_response, 'DateTime');

        if (is_string($dateTime) && preg_match('/^\d{14}$/', $dateTime)) {
            return substr($dateTime, 0, 8);
        }

        throw new RuntimeException('La transacción original no tiene fecha válida para devolución.');
    }

    private function customOrderId(PaymentTransaction $transaction): string
    {
        return $transaction->idempotency_key ?: 'ANDANDO-TXN-' . $transaction->id;
    }

    private function refundCustomOrderId(PaymentRefund $refund): string
    {
        return 'ANDANDO-REFUND-' . $refund->id;
    }
}