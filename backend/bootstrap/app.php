<?php

use App\Http\Middleware\CorsForStorage;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Middleware\HandleCors;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        /**
         * Confía en proxies durante desarrollo/local.
         */
        $middleware->trustProxies(at: '*');

        /**
         * Habilita soporte para APIs stateful con Sanctum.
         */
        $middleware->statefulApi();

        /**
         * Evita conflictos CSRF en consumo desde Flutter Web durante desarrollo.
         */
        $middleware->validateCsrfTokens(except: [
            '*',
        ]);

        /**
         * CORS general para rutas API.
         */
        $middleware->append(HandleCors::class);

        /**
         * CORS específico para imágenes públicas servidas desde /storage.
         */
        $middleware->append(CorsForStorage::class);

        /**
         * Alias opcional para aplicar CORS manualmente si alguna ruta lo necesita.
         */
        $middleware->alias([
            'storage.cors' => CorsForStorage::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        /**
         * Fuerza respuestas JSON para cualquier ruta API.
         *
         * Esto evita errores como:
         * Route [login] not defined
         *
         * cuando una ruta protegida con auth:sanctum recibe una petición
         * sin token válido.
         */
        $exceptions->shouldRenderJsonWhen(function ($request, \Throwable $e) {
            return $request->is('api/*') || $request->expectsJson();
        });

        /**
         * Respuesta clara cuando una ruta API protegida no tiene token válido.
         */
        $exceptions->render(function (AuthenticationException $e, $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return response()->json([
                    'message' => 'No autenticado.',
                ], 401);
            }

            return null;
        });

        /**
         * Respuesta clara para rutas API no encontradas.
         */
        $exceptions->render(function (NotFoundHttpException $e, $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return response()->json([
                    'message' => 'Ruta no encontrada.',
                ], 404);
            }

            return null;
        });
    })
    ->create();