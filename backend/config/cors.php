<?php

return [

    /**
     * Rutas donde Laravel aplicará reglas CORS.
     */
    'paths' => [
        'api/*',
        'sanctum/csrf-cookie',
    ],

    /**
     * Métodos HTTP permitidos.
     */
    'allowed_methods' => ['*'],

    /**
     * Orígenes permitidos durante desarrollo.
     */
    'allowed_origins' => ['*'],

    /**
     * Patrones de orígenes permitidos.
     */
    'allowed_origins_patterns' => [],

    /**
     * Headers permitidos.
     */
    'allowed_headers' => ['*'],

    /**
     * Headers expuestos al frontend.
     */
    'exposed_headers' => [],

    /**
     * Tiempo de cache del preflight request.
     */
    'max_age' => 0,

    /**
     * En desarrollo lo dejamos false porque allowed_origins está en '*'.
     */
    'supports_credentials' => false,
];