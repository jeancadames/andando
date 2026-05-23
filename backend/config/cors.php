<?php

return [

    /**
     * -------------------------------------------------------------------------
     * Rutas protegidas por CORS
     * -------------------------------------------------------------------------
     *
     * Aquí definimos qué rutas podrán ser consumidas desde
     * Flutter Web, aplicaciones móviles u otros dominios.
     *
     * IMPORTANTE:
     * Agregamos 'storage/*' porque las imágenes de experiencias
     * se sirven desde:
     *
     * /storage/provider-experiences/...
     *
     * Sin esto, Flutter Web bloquea las imágenes por política CORS.
     */
    'paths' => [
        'api/*',
        'storage/*',
        'sanctum/csrf-cookie',
    ],

    /**
     * -------------------------------------------------------------------------
     * Métodos HTTP permitidos
     * -------------------------------------------------------------------------
     *
     * Permitimos todos los métodos:
     * GET, POST, PUT, PATCH, DELETE, OPTIONS, etc.
     */
    'allowed_methods' => ['*'],

    /**
     * -------------------------------------------------------------------------
     * Orígenes permitidos
     * -------------------------------------------------------------------------
     *
     * Durante desarrollo permitimos cualquier origen.
     *
     * Esto permite conexiones desde:
     * - localhost
     * - Flutter Web
     * - emuladores
     * - dispositivos móviles
     *
     * En producción se recomienda limitar los dominios.
     */
    'allowed_origins' => ['*'],

    /**
     * -------------------------------------------------------------------------
     * Patrones de orígenes permitidos
     * -------------------------------------------------------------------------
     *
     * No usamos patrones dinámicos actualmente.
     */
    'allowed_origins_patterns' => [],

    /**
     * -------------------------------------------------------------------------
     * Headers permitidos
     * -------------------------------------------------------------------------
     *
     * Permitimos cualquier header:
     * - Authorization
     * - Content-Type
     * - Accept
     * etc.
     */
    'allowed_headers' => ['*'],

    /**
     * -------------------------------------------------------------------------
     * Headers expuestos al frontend
     * -------------------------------------------------------------------------
     *
     * Actualmente no necesitamos exponer headers adicionales.
     */
    'exposed_headers' => [],

    /**
     * -------------------------------------------------------------------------
     * Tiempo de cache del preflight request
     * -------------------------------------------------------------------------
     *
     * 0 = sin cache.
     */
    'max_age' => 0,

    /**
     * -------------------------------------------------------------------------
     * Soporte de credenciales
     * -------------------------------------------------------------------------
     *
     * Debe mantenerse en false mientras allowed_origins use '*'.
     *
     * Si luego usamos cookies/sesiones cross-domain,
     * esto deberá cambiar.
     */
    'supports_credentials' => false,
];