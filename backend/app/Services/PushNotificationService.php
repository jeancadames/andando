<?php

namespace App\Services;

use App\Models\User;

/**
 * Servicio preparado para notificaciones push.
 *
 * Ahora mismo NO envía nada porque Firebase no está implementado.
 * Cuando agregues Firebase, conectamos aquí el envío real.
 */
class PushNotificationService
{
    public function sendToUser(
        User $user,
        string $title,
        string $body,
        array $data = [],
    ): void {
        /**
         * Intencionalmente vacío por ahora.
         *
         * Aquí después conectaremos Firebase Cloud Messaging.
         *
         * Ya recibimos:
         * - usuario receptor
         * - título
         * - cuerpo
         * - data para abrir el chat
         */
    }
}