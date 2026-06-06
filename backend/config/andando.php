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
];