<?php

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
         * Agrega middleware CORS para permitir peticiones desde Flutter Web.
         */
        $middleware->append(HandleCors::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();