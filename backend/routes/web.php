<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::get('/', function () {
    return view('welcome');
});

// /*
// |--------------------------------------------------------------------------
// | Archivos públicos para Flutter Web
// |--------------------------------------------------------------------------
// |
// | Esta ruta sirve archivos desde:
// | - storage/app/public/{path}
// | - public/storage/{path}
// |
// | Funciona para:
// | - provider-experiences/...
// | - review-photos/...
// | - chat/conversations/...
// |
// | URL:
// | /storage/{path}
// |
// */
// Route::options('/storage/{path}', function () {
//     return response('', 204, [
//         'Access-Control-Allow-Origin' => '*',
//         'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
//         'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
//         'Access-Control-Expose-Headers' => 'Content-Type, Content-Length',
//         'Cross-Origin-Resource-Policy' => 'cross-origin',
//         'Cross-Origin-Embedder-Policy' => 'unsafe-none',
//     ]);
// })->where('path', '.*');

// Route::get('/storage/{path}', function (string $path) {
//     $path = trim(str_replace('\\', '/', rawurldecode($path)), '/');

//     if ($path === '' || str_contains($path, '..')) {
//         abort(404);
//     }

//     $disk = Storage::disk('public');

//     $storagePath = $disk->path($path);
//     $publicStoragePath = public_path('storage/' . $path);

//     if (is_file($storagePath)) {
//         $fullPath = $storagePath;
//     } elseif (is_file($publicStoragePath)) {
//         $fullPath = $publicStoragePath;
//     } else {
//         abort(404);
//     }

//     $mimeType = mime_content_type($fullPath) ?: 'application/octet-stream';

//     return response()->file($fullPath, [
//         'Content-Type' => $mimeType,
//         'Access-Control-Allow-Origin' => '*',
//         'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
//         'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
//         'Access-Control-Expose-Headers' => 'Content-Type, Content-Length',
//         'Cross-Origin-Resource-Policy' => 'cross-origin',
//         'Cross-Origin-Embedder-Policy' => 'unsafe-none',
//         'Cache-Control' => 'public, max-age=86400',
//     ]);
// })->where('path', '.*');