<?php

namespace App\Services\Payments\Azul;

class AzulPayloadSanitizer
{
    private const SENSITIVE_KEYS = [
        'cardnumber',
        'pan',
        'cvc',
        'cvv',
        'cvv2',
        'cvc2',
        'cid',
        'auth1',
        'auth2',
        'authorization',
        'password',
        'privatekey',
        'key',
        'datavaulttoken',
        'paymenttoken',
    ];

    public function sanitize(array $payload): array
    {
        $clean = [];

        foreach ($payload as $key => $value) {
            $normalizedKey = strtolower(
                preg_replace('/[^a-zA-Z0-9]/', '', (string) $key) ?? ''
            );

            if (in_array($normalizedKey, self::SENSITIVE_KEYS, true)) {
                $clean[$key] = blank($value) ? $value : '[REDACTED]';
                continue;
            }

            if (is_array($value)) {
                $clean[$key] = $this->sanitize($value);
                continue;
            }

            if (is_string($value)) {
                $clean[$key] = $this->maskPossibleCardNumber($value);
                continue;
            }

            $clean[$key] = $value;
        }

        return $clean;
    }

    private function maskPossibleCardNumber(string $value): string
    {
        $digitsOnly = preg_replace('/\D+/', '', $value);

        if (! is_string($digitsOnly) || strlen($digitsOnly) < 13 || strlen($digitsOnly) > 19) {
            return $value;
        }

        if (! $this->passesLuhnCheck($digitsOnly)) {
            return $value;
        }

        return substr($digitsOnly, 0, 6)
            . str_repeat('*', max(strlen($digitsOnly) - 10, 0))
            . substr($digitsOnly, -4);
    }

    private function passesLuhnCheck(string $digits): bool
    {
        $sum = 0;
        $alternate = false;

        for ($i = strlen($digits) - 1; $i >= 0; $i--) {
            $number = (int) $digits[$i];

            if ($alternate) {
                $number *= 2;

                if ($number > 9) {
                    $number -= 9;
                }
            }

            $sum += $number;
            $alternate = ! $alternate;
        }

        return $sum > 0 && $sum % 10 === 0;
    }
}