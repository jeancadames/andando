<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Bloquea cualquier acción de un proveedor suspendido en la API (Flutter).
 *
 * Se aplica al grupo autenticado de rutas de proveedor. Un proveedor con
 * status 'suspended' recibe 403 en todo (incluido crear experiencias y /me),
 * lo que hace que la app lo trate como sin acceso. Proveedores activos
 * (approved/pending) no se ven afectados.
 */
class CheckProviderActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $provider = $request->user()?->provider;

        if ($provider && $provider->status === 'suspended') {
            return response()->json([
                'message' => 'Tu cuenta de proveedor está suspendida. Contacta al soporte.',
                'code' => 'provider_suspended',
            ], 403);
        }

        return $next($request);
    }
}
