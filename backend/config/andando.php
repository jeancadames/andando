<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Comisión de AndanDO
    |--------------------------------------------------------------------------
    |
    | 0.15 = 15%
    | 0.12 = 12%
    | 0.18 = 18%
    |
    | Este valor se lee desde .env para poder cambiarlo sin tocar Flutter.
    |
    */
    'commission_rate' => (float) env('ANDANDO_COMMISSION_RATE', 0.15),


    /*
    |--------------------------------------------------------------------------
    | Politicas, correo y RNC de AndanDO
    |--------------------------------------------------------------------------
    |
    */

    'legal' => [
        'terms_version' => env('ANDANDO_TERMS_VERSION', 'v1.0'),
        'privacy_version' => env('ANDANDO_PRIVACY_VERSION', 'v1.0'),
        'cookies_version' => env('ANDANDO_COOKIES_VERSION', 'v1.0'),
        'rnc' => env('ANDANDO_RNC', '1-31-12345-6'),
        'support_email' => env('ANDANDO_SUPPORT_EMAIL', 'soporte@andando.com.do'),
    ],

];