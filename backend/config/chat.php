 <?php

return [

    /*
    |--------------------------------------------------------------------------
    | Horas antes de cerrar una conversación por inactividad
    |--------------------------------------------------------------------------
    |
    | Por defecto: 72 horas.
    | Puedes cambiarlo en .env:
    |
    | CHAT_AUTO_CLOSE_HOURS=72
    |
    */

    'auto_close_hours' => (int) env('CHAT_AUTO_CLOSE_HOURS', 72),

    /*
    |--------------------------------------------------------------------------
    | Mensaje informativo para mostrar en Flutter
    |--------------------------------------------------------------------------
    */

    'inactivity_notice' => env(
        'CHAT_INACTIVITY_NOTICE',
        'Este chat se cierra automáticamente después de 72 horas sin interacción.'
    ),

    /*
    |--------------------------------------------------------------------------
    | Adjuntos
    |--------------------------------------------------------------------------
    */

    'max_image_size_kb' => (int) env('CHAT_MAX_IMAGE_SIZE_KB', 5120),

    'allowed_image_mimes' => [
        'jpg',
        'jpeg',
        'png',
        'webp',
    ],

];