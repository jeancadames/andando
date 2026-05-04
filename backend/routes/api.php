<?php

use App\Http\Controllers\Api\Customer\CustomerAuthController;
use App\Http\Controllers\Api\Provider\ProviderAuthController;
use App\Http\Controllers\Api\Provider\ProviderDashboardController;
use App\Http\Controllers\Api\Provider\ProviderExperienceController;
use App\Http\Controllers\Api\Provider\ProviderExperienceScheduleController;
use Illuminate\Support\Facades\Route;

Route::prefix('provider')->group(function () {
    /*
    |--------------------------------------------------------------------------
    | Rutas públicas de afiliado/proveedor
    |--------------------------------------------------------------------------
    |
    | Estas no requieren token.
    */
    Route::post('/register', [ProviderAuthController::class, 'register']);
    Route::post('/login', [ProviderAuthController::class, 'login']);

    /*
    |--------------------------------------------------------------------------
    | Rutas protegidas de afiliado/proveedor
    |--------------------------------------------------------------------------
    |
    | Estas sí requieren:
    | Authorization: Bearer <token>
    */
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

/**
 * Grupo de rutas para clientes
 */
Route::prefix('customer')->group(function () {

    /**
     * Crear cuenta de cliente
     *
     * POST /api/customer/register
     */
    Route::post('/register', [CustomerAuthController::class, 'register']);
});