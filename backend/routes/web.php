<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Aquí se registran las rutas web de Laravel.
| Estas rutas utilizan el middleware "web".
|
*/

/**
 * Ruta principal temporal de Laravel.
 *
 * Puede eliminarse más adelante cuando Flutter sea
 * el único frontend de la aplicación.
 */
Route::get('/', function () {
    return view('welcome');
});

/**
 * Servidor manual de archivos públicos con soporte CORS.
 *
 * Flutter Web corre normalmente desde:
 * http://localhost:xxxxx
 *
 * Mientras Laravel corre desde:
 * http://127.0.0.1:8000
 *
 * El navegador considera eso como distintos origins,
 * por lo que bloquea las imágenes sin headers CORS.
 *
 * Esta ruta:
 * 1. Busca el archivo dentro del disk "public"
 * 2. Lo devuelve como response file
 * 3. Aplica el middleware storage.cors
 *
 * Ejemplo de URL:
 * /storage/provider-experiences/provider_2/experience_1/photo.png
 */
Route::get('/storage/{path}', function (string $path) {

    /**
     * Verifica que el archivo exista.
     */
    if (! Storage::disk('public')->exists($path)) {
        abort(404);
    }

    /**
     * Devuelve el archivo físico.
     */
    return response()->file(
        Storage::disk('public')->path($path)
    );

})
    /**
     * Permite rutas anidadas completas.
     */
    ->where('path', '.*')

    /**
     * Middleware que agrega headers CORS.
     */
    ->middleware('storage.cors');