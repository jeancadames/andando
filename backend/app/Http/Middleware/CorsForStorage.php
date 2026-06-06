<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsForStorage
{
    public function handle(Request $request, Closure $next): Response
    {
        $isPublicFileRequest =
            $request->is('storage/*') ||
            $request->is('api/storage/*') ||
            $request->is('public-files/*') ||
            $request->is('api/public-files/*');

        if (! $isPublicFileRequest) {
            return $next($request);
        }

        $headers = [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
            'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
            'Access-Control-Expose-Headers' => 'Content-Type, Content-Length, Content-Disposition',
            'Cross-Origin-Resource-Policy' => 'cross-origin',
            'Cross-Origin-Embedder-Policy' => 'unsafe-none',
        ];

        if ($request->isMethod('OPTIONS')) {
            return response('', 204, $headers);
        }

        $response = $next($request);

        foreach ($headers as $key => $value) {
            $response->headers->set($key, $value);
        }

        return $response;
    }
}