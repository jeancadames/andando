<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;

Route::get('/', fn () => Inertia::render('Home'))->name('home');

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
// === AndanDO Admin Panel (agregado por setup-andando-admin.ps1) ===
Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest')->group(function () {
        Route::get('login', [\App\Http\Controllers\Admin\AuthController::class, 'create'])->name('login');
        Route::post('login', [\App\Http\Controllers\Admin\AuthController::class, 'store'])->name('login.store');
    });
    Route::middleware(['auth', 'admin'])->group(function () {
        Route::post('logout', [\App\Http\Controllers\Admin\AuthController::class, 'destroy'])->name('logout');
        Route::get('/', [\App\Http\Controllers\Admin\DashboardController::class, 'index'])->name('dashboard');

        Route::get('afiliados', [\App\Http\Controllers\Admin\VerificationRequestController::class, 'index'])->name('affiliates.index');
        Route::get('afiliados/{verificationRequest}', [\App\Http\Controllers\Admin\VerificationRequestController::class, 'show'])->name('affiliates.show');
        Route::post('afiliados/{verificationRequest}/aprobar', [\App\Http\Controllers\Admin\VerificationRequestController::class, 'approve'])->name('affiliates.approve');
        Route::post('afiliados/{verificationRequest}/rechazar', [\App\Http\Controllers\Admin\VerificationRequestController::class, 'reject'])->name('affiliates.reject');

        Route::get('documentos/{document}', [\App\Http\Controllers\Admin\DocumentController::class, 'show'])->name('documents.show');

        Route::get('reclamos', [\App\Http\Controllers\Admin\ClaimController::class, 'index'])->name('claims.index');
        Route::get('reclamos/{claim}', [\App\Http\Controllers\Admin\ClaimController::class, 'show'])->name('claims.show');
        Route::post('reclamos/{claim}/resolver', [\App\Http\Controllers\Admin\ClaimController::class, 'resolve'])->name('claims.resolve');
        Route::post('reclamos/{claim}/rechazar', [\App\Http\Controllers\Admin\ClaimController::class, 'reject'])->name('claims.reject');

        Route::get('experiencias', [\App\Http\Controllers\Admin\ExperienceController::class, 'index'])->name('experiences.index');
        Route::get('experiencias/{experience}', [\App\Http\Controllers\Admin\ExperienceController::class, 'show'])->name('experiences.show');
        Route::post('experiencias/{experience}/estado', [\App\Http\Controllers\Admin\ExperienceController::class, 'toggleActive'])->name('experiences.toggle');
        Route::post('experiencias/{experience}/rechazar', [\App\Http\Controllers\Admin\ExperienceController::class, 'reject'])->name('experiences.reject');
    });
});
