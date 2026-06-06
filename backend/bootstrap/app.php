<?php

use App\Http\Middleware\CorsForStorage;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Middleware\HandleCors;

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
         *
         * Se registra global porque /storage/{path} lo está sirviendo
         * Laravel internamente como storage.local, no nuestra ruta manual.
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
        //
    })
    ->create();