<?php

namespace App\Services\Payments;

use App\Services\Payments\Azul\AzulClient;
use RuntimeException;

class AzulPaymentService
{
    public function __construct(
        private readonly AzulClient $client,
    ) {}

    public function isEnabled(): bool
    {
        return (bool) config('azul.enabled');
    }

    public function tokenizeCard(array $cardData): array
    {
        $cardNumber = preg_replace('/\D/', '', $cardData['card_number'] ?? '');
        $cvv = preg_replace('/\D/', '', $cardData['cvv'] ?? '');

        if ($cardNumber === '' || $cvv === '') {
            throw new RuntimeException('Datos de tarjeta incompletos.');
        }

        $brand = $this->detectBrand($cardNumber);
        $last4 = substr($cardNumber, -4);

        if (! $this->isEnabled()) {
            return [
                'success' => true,
                'token' => 'azul_mock_' . bin2hex(random_bytes(16)),
                'brand' => $brand,
                'last4' => $last4,
                'masked_card_number' => $this->maskCardNumber($cardNumber),
                'token_expires_at' => null,
                'response_code' => 'MOCK',
                'response_message' => 'Tokenización simulada. AZUL deshabilitado.',
                'raw_response' => [
                    'mode' => 'mock',
                    'gateway' => 'azul',
                    'brand' => $brand,
                    'last4' => $last4,
                ],
            ];
        }

        $this->ensureConfigured();

        $expiration = sprintf(
            '%04d%02d',
            (int) $cardData['expiry_year'],
            (int) $cardData['expiry_month']
        );

        $response = $this->client->post('ProcessDatavault', [
            'Channel' => config('azul.channel'),
            'Store' => config('azul.merchant_id'),
            'CardNumber' => $cardNumber,
            'Expiration' => $expiration,
            'CVC' => $cvv,
            'TrxType' => 'CREATE',
        ]);

        $safeResponse = $this->client->sanitizeForStorage($response);

        $success = ($response['IsoCode'] ?? null) === '00'
            && ! blank($response['DataVaultToken'] ?? null);

        if (! $success) {
            return [
                'success' => false,
                'response_code' => $response['ResponseCode'] ?? null,
                'iso_code' => $response['IsoCode'] ?? null,
                'response_message' => $response['ResponseMessage'] ?? null,
                'error_description' => $response['ErrorDescription'] ?? 'No se pudo tokenizar la tarjeta.',
                'raw_response' => $safeResponse,
            ];
        }

        $maskedCard = $this->isMaskedCardNumber($response['CardNumber'] ?? null)
            ? $response['CardNumber']
            : $this->maskCardNumber($cardNumber);

        $expirationFromAzul = $response['Expiration'] ?? $expiration;

        return [
            'success' => true,
            'token' => $response['DataVaultToken'],
            'brand' => strtolower($response['Brand'] ?? $brand),
            'last4' => $last4,
            'masked_card_number' => $maskedCard,
            'token_expires_at' => $this->expirationToDate($expirationFromAzul),
            'response_code' => $response['ResponseCode'] ?? null,
            'iso_code' => $response['IsoCode'] ?? null,
            'response_message' => $response['ResponseMessage'] ?? null,
            'raw_response' => $safeResponse,
        ];
    }

    public function deleteToken(string $token): array
    {
        if ($token === '') {
            throw new RuntimeException('Token inválido.');
        }

        if (! $this->isEnabled()) {
            return [
                'success' => true,
                'response_code' => 'MOCK',
                'response_message' => 'Eliminación de token simulada.',
                'raw_response' => [
                    'mode' => 'mock',
                    'gateway' => 'azul',
                    'token_deleted' => true,
                ],
            ];
        }

        $this->ensureConfigured();

        $response = $this->client->post('ProcessDatavault', [
            'Channel' => config('azul.channel'),
            'Store' => config('azul.merchant_id'),
            'DataVaultToken' => $token,
            'TrxType' => 'DELETE',
        ]);

        return [
            'success' => ($response['IsoCode'] ?? null) === '00',
            'response_code' => $response['ResponseCode'] ?? null,
            'iso_code' => $response['IsoCode'] ?? null,
            'response_message' => $response['ResponseMessage'] ?? null,
            'error_description' => $response['ErrorDescription'] ?? null,
            'raw_response' => $this->client->sanitizeForStorage($response),
        ];
    }

    private function ensureConfigured(): void
    {
        foreach (['merchant_id', 'auth1', 'auth2', 'base_url', 'cert_path', 'key_path'] as $key) {
            if (blank(config("azul.$key"))) {
                throw new RuntimeException("Falta configurar AZUL: {$key}.");
            }
        }
    }

    public function detectBrand(string $cardNumber): string
    {
        if (str_starts_with($cardNumber, '4')) {
            return 'visa';
        }

        if (str_starts_with($cardNumber, '34') || str_starts_with($cardNumber, '37')) {
            return 'amex';
        }

        $firstTwo = (int) substr($cardNumber, 0, 2);
        $firstFour = (int) substr($cardNumber, 0, 4);
        $firstThree = (int) substr($cardNumber, 0, 3);

        if (($firstTwo >= 51 && $firstTwo <= 55) || ($firstFour >= 2221 && $firstFour <= 2720)) {
            return 'mastercard';
        }

        if ($firstFour === 6011 || str_starts_with($cardNumber, '65') || ($firstThree >= 644 && $firstThree <= 649)) {
            return 'discover';
        }

        return 'unknown';
    }

    private function maskCardNumber(string $cardNumber): string
    {
        return '•••• •••• •••• ' . substr($cardNumber, -4);
    }

    private function expirationToDate(?string $expiration): ?string
    {
        if (! is_string($expiration) || ! preg_match('/^\d{6}$/', $expiration)) {
            return null;
        }

        return substr($expiration, 0, 4) . '-' . substr($expiration, 4, 2) . '-01 00:00:00';
    }

    private function isMaskedCardNumber(mixed $value): bool
    {
        return is_string($value)
            && str_contains($value, '*')
            && strlen($value) <= 25;
    }
}