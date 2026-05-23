<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsForStorage
{
    /**
     * Agrega headers CORS a las respuestas de archivos servidos desde /storage.
     *
     * Esto permite que Flutter Web cargue imágenes desde Laravel localmente:
     * http://localhost:xxxxx -> http://127.0.0.1:8000/storage/...
     */
    public function handle(Request $request, Closure $next): Response
    {
        /**
         * Respuesta para preflight requests.
         */
        if ($request->isMethod('OPTIONS')) {
            return response('', 204)
                ->header('Access-Control-Allow-Origin', '*')
                ->header('Access-Control-Allow-Methods', 'GET, OPTIONS')
                ->header(
                    'Access-Control-Allow-Headers',
                    'Origin, Content-Type, Accept, Authorization'
                );
        }

        $response = $next($request);

        $response->headers->set('Access-Control-Allow-Origin', '*');
        $response->headers->set('Access-Control-Allow-Methods', 'GET, OPTIONS');
        $response->headers->set(
            'Access-Control-Allow-Headers',
            'Origin, Content-Type, Accept, Authorization'
        );

        return $response;
    }
}