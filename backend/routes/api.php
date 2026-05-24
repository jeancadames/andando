<?php

use App\Http\Controllers\Api\Client\ClientProfileController;
use App\Http\Controllers\Api\Auth\LoginController;
use App\Http\Controllers\Api\Client\ClientBookingController;
use App\Http\Controllers\Api\Client\ClientFavoriteExperienceController;
use App\Http\Controllers\Api\Client\ExploreController;
use App\Http\Controllers\Api\Customer\CustomerAuthController;
use App\Http\Controllers\Api\Provider\ProviderAuthController;
use App\Http\Controllers\Api\Provider\ProviderDashboardController;
use App\Http\Controllers\Api\Provider\ProviderExperienceController;
use App\Http\Controllers\Api\Provider\ProviderExperienceScheduleController;
use App\Http\Controllers\Api\Provider\ProviderAnalyticsController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Rutas públicas y protegidas consumidas por Flutter.
|
*/

/*
|--------------------------------------------------------------------------
| Archivos públicos con CORS para Flutter Web
|--------------------------------------------------------------------------
|
| php artisan serve no usa .htaccess.
| Por eso servimos las imágenes desde /api/storage/{path}.
|
| Ejemplo:
| /api/storage/provider-experiences/provider_2/experience_1/foto.png
|
*/
Route::get('/storage/{path}', function (string $path) {
    if (! Storage::disk('public')->exists($path)) {
        abort(404);
    }

    return response()->file(
        Storage::disk('public')->path($path),
        [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization',
        ]
    );
})->where('path', '.*');

/*
|--------------------------------------------------------------------------
| Autenticación general
|--------------------------------------------------------------------------
*/
Route::post('/auth/login', LoginController::class);

/*
|--------------------------------------------------------------------------
| Rutas de proveedor
|--------------------------------------------------------------------------
*/
Route::prefix('provider')->group(function () {
    Route::post('/register', [ProviderAuthController::class, 'register']);
    Route::post('/login', [ProviderAuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [ProviderAuthController::class, 'me']);
        Route::post('/logout', [ProviderAuthController::class, 'logout']);

        Route::get('/dashboard', ProviderDashboardController::class);
        Route::get('/bookings/upcoming', [ProviderDashboardController::class, 'upcomingBookings']);

        Route::get('/experiences', [ProviderExperienceController::class, 'index']);
        Route::post('/experiences', [ProviderExperienceController::class, 'store']);
        Route::get('/experiences/{experience}', [ProviderExperienceController::class, 'show']);
        Route::post('/experiences/{experience}', [ProviderExperienceController::class, 'update']);
        Route::delete('/experiences/{experience}', [ProviderExperienceController::class, 'destroy']);
        Route::post('/experiences/{experience}/publish', [ProviderExperienceController::class, 'publish']);
        Route::post('/experiences/{experience}/pause', [ProviderExperienceController::class, 'pause']);

        Route::get('/experiences/{experience}/schedules', [ProviderExperienceScheduleController::class, 'index']);
        Route::post('/experiences/{experience}/schedules', [ProviderExperienceScheduleController::class, 'store']);
        Route::put('/experiences/{experience}/schedules/{schedule}', [ProviderExperienceScheduleController::class, 'update']);
        Route::delete('/experiences/{experience}/schedules/{schedule}', [ProviderExperienceScheduleController::class, 'destroy']);

        Route::get('/experiences/{experience}/schedules/{schedule}/bookings',[ProviderExperienceScheduleController::class, 'bookings']);

        Route::get('/analytics', ProviderAnalyticsController::class);
        
    });
});

/*
|--------------------------------------------------------------------------
| Rutas de registro cliente
|--------------------------------------------------------------------------
*/
Route::prefix('customer')->group(function () {
    Route::post('/register', [CustomerAuthController::class, 'register']);
});

/*
|--------------------------------------------------------------------------
| Exploración pública para clientes y visitantes
|--------------------------------------------------------------------------
*/
Route::prefix('client/explore')->group(function () {
    Route::get('/experiences', [ExploreController::class, 'index']);
    Route::get('/experiences/categories', [ExploreController::class, 'categories']);
    Route::get('/experiences/{id}', [ExploreController::class, 'show']);
});

/*
|--------------------------------------------------------------------------
| Rutas protegidas del cliente
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->prefix('client')->group(function () {
    Route::get('/profile', [ClientProfileController::class, 'show']);
    Route::put('/profile', [ClientProfileController::class, 'update']);
    Route::post('/profile/photo', [ClientProfileController::class, 'updatePhoto']);
    Route::post('/logout', [ClientProfileController::class, 'logout']);

    Route::get('/bookings', [ClientBookingController::class, 'index']);
    Route::post('/bookings', [ClientBookingController::class, 'store']);

    Route::post('/experiences/{experience}/favorite', [ClientFavoriteExperienceController::class, 'store']);
    Route::delete('/experiences/{experience}/favorite', [ClientFavoriteExperienceController::class, 'destroy']);
});