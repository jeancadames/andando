<?php

return [
    'enabled' => env('AZUL_ENABLED', false),
    'environment' => env('AZUL_ENV', 'sandbox'),

    'merchant_id' => env('AZUL_MERCHANT_ID'),
    'auth_key' => env('AZUL_AUTH_KEY'),
    'terminal_id' => env('AZUL_TERMINAL_ID'),
    'base_url' => env('AZUL_BASE_URL'),
];