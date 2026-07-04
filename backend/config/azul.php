<?php

return [
    'enabled' => env('AZUL_ENABLED', false),
    'environment' => env('AZUL_ENVIRONMENT', 'staging'),

    'base_url' => env('AZUL_BASE_URL', 'https://pruebas.azul.com.do'),
    'merchant_id' => env('AZUL_MERCHANT_ID'),

    'auth1' => env('AZUL_AUTH1'),
    'auth2' => env('AZUL_AUTH2'),

    'cert_path' => env('AZUL_CERT_PATH'),
    'key_path' => env('AZUL_KEY_PATH'),

    'channel' => env('AZUL_CHANNEL', 'EC'),
    'pos_input_mode' => env('AZUL_POS_INPUT_MODE', 'E-Commerce'),

    'currency_pos_code' => env('AZUL_CURRENCY_POS_CODE', '$'),
    'payments' => env('AZUL_PAYMENTS', '1'),
    'plan' => env('AZUL_PLAN', '0'),
    'acquirer_ref_data' => env('AZUL_ACQUIRER_REF_DATA', '1'),

    /*
     * Null = no enviar ForceNo3DS.
     * "0" = procesar con 3DS.
     * "1" = procesar sin 3DS.
     *
     * En staging puede usarse "1" si Azul lo habilitó para pruebas.
     * Para producción, esto debe revisarse contra el flujo 3DS completo.
     */
    'force_no_3ds' => env('AZUL_FORCE_NO_3DS'),

    'customer_service_phone' => env('AZUL_CUSTOMER_SERVICE_PHONE', ''),
    'ecommerce_url' => env('AZUL_ECOMMERCE_URL', ''),
    'alt_merchant_name' => env('AZUL_ALT_MERCHANT_NAME', ''),

    'timeout' => env('AZUL_TIMEOUT', 120),
    'connect_timeout' => env('AZUL_CONNECT_TIMEOUT', 15),
];