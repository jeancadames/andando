<?php

namespace App\Services\Payments\Azul;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class AzulClient
{
    public function __construct(
        private readonly AzulPayloadSanitizer $sanitizer,
    ) {}

    public function post(string $operation, array $payload): array
    {
        if (! config('azul.enabled')) {
            throw new RuntimeException('Azul WebServices no está habilitado.');
        }

        $url = rtrim((string) config('azul.base_url'), '/')
            . '/WebServices/JSON/Default.aspx'
            . ($operation !== '' ? '?' . $operation : '');

        $response = Http::timeout((int) config('azul.timeout'))
            ->connectTimeout((int) config('azul.connect_timeout'))
            ->withHeaders([
                'Auth1' => (string) config('azul.auth1'),
                'Auth2' => (string) config('azul.auth2'),
                'Content-Type' => 'application/json',
            ])
            ->withOptions([
                'cert' => (string) config('azul.cert_path'),
                'ssl_key' => (string) config('azul.key_path'),
                'verify' => true,
            ])
            ->post($url, $payload);

        if (! $response->successful()) {
            throw new RuntimeException('Error HTTP comunicando con Azul.');
        }

        $json = $response->json();

        if (! is_array($json)) {
            throw new RuntimeException('Azul respondió con JSON inválido.');
        }

        return $json;
    }

    public function sanitizeForStorage(array $payload): array
    {
        return $this->sanitizer->sanitize($payload);
    }
}