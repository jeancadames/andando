<?php

namespace App\Services\Payments;

use RuntimeException;

/**
 * Servicio base para integración con AZUL Datavault.
 *
 * Este servicio centraliza:
 * - tokenización de tarjetas.
 * - eliminación de tokens.
 * - detección de marca.
 * - extracción de últimos 4 dígitos.
 *
 * IMPORTANTE:
 * Mientras AZUL_ENABLED=false, trabaja en modo simulado.
 * Cuando tengas credenciales reales de AZUL, aquí se conectan los Webservices.
 */
class AzulPaymentService
{
    /**
     * Indica si la integración real con AZUL está activa.
     */
    public function isEnabled(): bool
    {
        return (bool) config('azul.enabled');
    }

    /**
     * Tokeniza una tarjeta usando AZUL Datavault.
     *
     * En modo real:
     * - Laravel enviará los datos temporalmente a AZUL.
     * - AZUL devolverá un DataVaultToken.
     * - AndanDO guardará solo el token y datos seguros.
     */
    public function tokenizeCard(array $cardData): array
    {
        $cardNumber = preg_replace('/\D/', '', $cardData['card_number'] ?? '');
        $cvv = preg_replace('/\D/', '', $cardData['cvv'] ?? '');

        if ($cardNumber === '' || $cvv === '') {
            throw new RuntimeException('Datos de tarjeta incompletos.');
        }

        $brand = $this->detectBrand($cardNumber);
        $last4 = substr($cardNumber, -4);

        /**
         * MODO SIMULADO:
         * Permite seguir desarrollando sin credenciales reales de AZUL.
         */
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

        /**
         * AQUÍ irá la llamada real a AZUL Datavault Create.
         *
         * Cuando AZUL entregue credenciales/endpoints finales,
         * este bloque se reemplaza por la petición HTTP real.
         */
        throw new RuntimeException(
            'Tokenización real con AZUL pendiente de configurar.'
        );
    }

    /**
     * Elimina/desactiva un token en AZUL Datavault.
     */
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

        /**
         * AQUÍ irá la llamada real a AZUL Datavault Delete.
         */
        throw new RuntimeException(
            'Eliminación real de token AZUL pendiente de configurar.'
        );
    }

    /**
     * Valida que las credenciales mínimas existan.
     */
    private function ensureConfigured(): void
    {
        foreach (['merchant_id', 'auth_key', 'terminal_id', 'base_url'] as $key) {
            if (blank(config("azul.$key"))) {
                throw new RuntimeException("Falta configurar AZUL: {$key}.");
            }
        }
    }

    /**
     * Detecta marca de tarjeta por prefijo.
     */
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

    /**
     * Devuelve tarjeta enmascarada.
     */
    private function maskCardNumber(string $cardNumber): string
    {
        $last4 = substr($cardNumber, -4);

        return '•••• •••• •••• ' . $last4;
    }
}