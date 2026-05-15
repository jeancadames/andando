<?php

use App\Http\Controllers\Api\Auth\LoginController;
use App\Http\Controllers\Api\Client\ExploreController;
use App\Http\Controllers\Api\Customer\CustomerAuthController;
use App\Http\Controllers\Api\Provider\ProviderAuthController;
use App\Http\Controllers\Api\Provider\ProviderDashboardController;
use App\Http\Controllers\Api\Provider\ProviderExperienceController;
use App\Http\Controllers\Api\Provider\ProviderExperienceScheduleController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Login general
|--------------------------------------------------------------------------
|
| POST /api/auth/login
|
| Permite iniciar sesión a:
| - clientes
| - afiliados/proveedores
*/
Route::post('/auth/login', LoginController::class);

Route::prefix('provider')->group(function () {
    Route::post('/register', [ProviderAuthController::class, 'register']);
    Route::post('/login', [ProviderAuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [ProviderAuthController::class, 'me']);
        Route::post('/logout', [ProviderAuthController::class, 'logout']);

        Route::get('/dashboard', ProviderDashboardController::class);

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
    });
});

Route::prefix('customer')->group(function () {
    Route::post('/register', [CustomerAuthController::class, 'register']);
});

Route::prefix('client/explore')->group(function () {
    Route::get('/experiences', [ExploreController::class, 'index']);
    Route::get('/experiences/categories', [ExploreController::class, 'categories']);
    Route::get('/experiences/{id}', [ExploreController::class, 'show']);
});