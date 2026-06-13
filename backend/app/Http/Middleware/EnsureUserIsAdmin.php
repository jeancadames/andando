<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Permite el paso solo a usuarios cuyo type sea 'admin'.
 *
 * La redirección de invitados (no autenticados) la maneja el middleware
 * 'auth' antes de llegar aquí, así que en este punto el usuario ya existe;
 * solo validamos que sea administrador.
 */
class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user || $user->type !== 'admin') {
            abort(403, 'Acceso restringido al panel administrativo.');
        }

        return $next($request);
    }
}
