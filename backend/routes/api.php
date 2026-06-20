<?php

use App\Http\Controllers\Api\Auth\PasswordResetController;

use App\Http\Controllers\Api\Client\ClientPasswordController;
use App\Http\Controllers\Api\Client\ClientLegalSettingsController;
use App\Http\Controllers\Api\Auth\GoogleAuthController;
use App\Http\Controllers\Api\Auth\LoginController;

use App\Http\Controllers\Api\Client\ClientReviewCommentController;
use App\Http\Controllers\Api\Client\ClientReviewController;
use App\Http\Controllers\Api\Client\ClientProfileController;
use App\Http\Controllers\Api\Client\ClientConversationController;
use App\Http\Controllers\Api\Customer\CustomerAuthController;
use App\Http\Controllers\Api\Client\ClientBookingController;
use App\Http\Controllers\Api\Client\ClientFavoriteExperienceController;
use App\Http\Controllers\Api\Client\ExploreController;
use App\Http\Controllers\Api\Provider\ProviderAuthController;
use App\Http\Controllers\Api\Provider\ProviderDashboardController;
use App\Http\Controllers\Api\Provider\ProviderExperienceController;
use App\Http\Controllers\Api\Provider\ProviderExperienceScheduleController;
use App\Http\Controllers\Api\Provider\ProviderAnalyticsController;
use App\Http\Controllers\Api\Provider\ProviderExperienceReviewController;
use App\Http\Controllers\Api\Provider\ProviderConversationController;
use App\Http\Controllers\Api\Provider\ProviderPricingSettingController;
use App\Http\Controllers\Api\Client\ClientPaymentMethodController;
use App\Http\Controllers\Api\Client\ClientPaymentTransactionController;
use App\Http\Controllers\Api\Client\ClientClaimController;
use App\Http\Controllers\Api\Provider\ProviderClaimController;


use App\Http\Controllers\Api\DeviceTokenController;
use App\Http\Controllers\Api\Provider\ProviderPlacesController;
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
| Archivos públicos para Flutter Web
|--------------------------------------------------------------------------
|
| Esta ruta sirve archivos desde:
| - storage/app/public/{path}
| - public/storage/{path}
|
| Funciona para:
| - provider-experiences/...
| - review-photos/...
| - chat/conversations/...
|
| URL:
| /api/storage/{path}
|
*/
Route::options('/public-files/{path}', function () {
    return response('', 204, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
        'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Expose-Headers' => 'Content-Type, Content-Length, Content-Disposition',
        'Cross-Origin-Resource-Policy' => 'cross-origin',
        'Cross-Origin-Embedder-Policy' => 'unsafe-none',
    ]);
})->where('path', '.*');

Route::get('/public-files/{path}', function (string $path) {
    $path = trim(str_replace('\\', '/', rawurldecode($path)), '/');

    if ($path === '' || str_contains($path, '..')) {
        abort(404);
    }

    $candidatePaths = [
        storage_path('app/public/' . $path),
        public_path('storage/' . $path),
    ];

    $fullPath = null;

    foreach ($candidatePaths as $candidatePath) {
        if (is_file($candidatePath)) {
            $fullPath = $candidatePath;
            break;
        }
    }

    if ($fullPath === null) {
        abort(404);
    }

    $mimeType = mime_content_type($fullPath) ?: 'application/octet-stream';
    $fileName = basename($fullPath);
    $fileSize = filesize($fullPath);

    $headers = [
        'Content-Type' => $mimeType,
        'Content-Length' => $fileSize,
        'Content-Disposition' => 'inline; filename="' . $fileName . '"',
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
        'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Expose-Headers' => 'Content-Type, Content-Length, Content-Disposition',
        'Cross-Origin-Resource-Policy' => 'cross-origin',
        'Cross-Origin-Embedder-Policy' => 'unsafe-none',
        'Cache-Control' => 'public, max-age=86400',
    ];

    return response()->stream(function () use ($fullPath) {
        /*
         * Limpia cualquier espacio, BOM, echo accidental o salida previa
         * antes de enviar los bytes reales de la imagen.
         */
        while (ob_get_level() > 0) {
            @ob_end_clean();
        }

        $handle = fopen($fullPath, 'rb');

        if ($handle !== false) {
            fpassthru($handle);
            fclose($handle);
        }
    }, 200, $headers);
})->where('path', '.*');
/*
|--------------------------------------------------------------------------
| Autenticación general
|--------------------------------------------------------------------------
*/
Route::post('/auth/login', LoginController::class);

<<<<<<< HEAD
Route::post('/forgot-password', [PasswordResetController::class, 'forgot']);
Route::post('/reset-password', [PasswordResetController::class, 'reset']);
=======
Route::post('/auth/google', GoogleAuthController::class);
>>>>>>> 245c78399b7b14f63a668e366607aa71db0ddb05

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/device-tokens', [DeviceTokenController::class, 'store']);
    Route::delete('/device-tokens', [DeviceTokenController::class, 'destroy']);
});

/*
|--------------------------------------------------------------------------
| Rutas de proveedor
|--------------------------------------------------------------------------
*/
Route::prefix('provider')->group(function () {
    Route::post('/register', [ProviderAuthController::class, 'register']);
    Route::post('/login', [ProviderAuthController::class, 'login']);

    Route::middleware(['auth:sanctum', 'provider.active'])->group(function () {
        Route::get('/me', [ProviderAuthController::class, 'me']);
        Route::post('/logout', [ProviderAuthController::class, 'logout']);

        Route::get('/pricing-settings', [ProviderPricingSettingController::class, 'index']);

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

        Route::get('/places/search', [ProviderPlacesController::class, 'search']);

        Route::get('/analytics', ProviderAnalyticsController::class);

        Route::get(
            '/experiences/{experience}/reviews/summary',
            [ProviderExperienceReviewController::class, 'summary']
        );

        Route::get(
            '/experiences/{experience}/reviews',
            [ProviderExperienceReviewController::class, 'index']
        );

        Route::post(
            '/experiences/{experience}/reviews/{review}/reply',
            [ProviderExperienceReviewController::class, 'reply']
        );
        
        Route::delete(
            '/experiences/{experience}/reviews/{review}/reply',
            [ProviderExperienceReviewController::class, 'deleteReply']
        );

        Route::get('/conversations', [ProviderConversationController::class, 'index']);
        Route::get('/conversations/unread-count', [ProviderConversationController::class, 'unreadCount']);
        Route::get('/conversations/{conversation}', [ProviderConversationController::class, 'show']);
        Route::get('/conversations/{conversation}/messages', [ProviderConversationController::class, 'messages']);
        Route::post('/conversations/{conversation}/messages', [ProviderConversationController::class, 'sendMessage']);
        Route::post('/conversations/{conversation}/read', [ProviderConversationController::class, 'markAsRead']);
        Route::post('/conversations/{conversation}/close', [ProviderConversationController::class, 'close']);


        Route::get('/claims', [ProviderClaimController::class, 'index']);

        Route::get('/claims/{claim}', [ProviderClaimController::class, 'show']);

        Route::post(
            '/claims/{claim}/reply',
            [ProviderClaimController::class, 'reply']
        );
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
    Route::get('/experiences/{experience}/reviews', [ClientReviewController::class, 'experienceReviews']);
    
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
        Route::put('/profile/password', [ClientPasswordController::class, 'update']);
        
        Route::get('/bookings', [ClientBookingController::class, 'index']);
        Route::post('/bookings', [ClientBookingController::class, 'store']);
        Route::get('/bookings/{booking}/receipt', [ClientBookingController::class, 'receipt']);
        Route::patch('/bookings/{booking}/cancel', [ClientBookingController::class, 'cancel']);
        Route::get('/bookings/{booking}/cancellation-preview', [ClientBookingController::class, 'cancellationPreview']);
        Route::patch('/bookings/{booking}/cancel', [ClientBookingController::class, 'cancel']);

        Route::get('/claims', [ClientClaimController::class, 'index']);
        Route::post('/claims', [ClientClaimController::class, 'store']);
        Route::get('/claims/{claim}', [ClientClaimController::class, 'show']);

        Route::post('/experiences/{experience}/favorite', [ClientFavoriteExperienceController::class, 'store']);
        Route::delete('/experiences/{experience}/favorite', [ClientFavoriteExperienceController::class, 'destroy']);
        
        Route::get('/experiences/{experience}/reviews', [ClientReviewController::class, 'experienceReviews']);
        Route::post('/reviews', [ClientReviewController::class, 'store']);
        Route::put('/reviews/{review}', [ClientReviewController::class, 'update']);
        Route::delete('/reviews/{review}', [ClientReviewController::class, 'destroy']);
        Route::delete('/reviews/{review}/photos/{photo}', [ClientReviewController::class, 'destroyPhoto']);
        Route::get('/reviews/{review}/comments', [ClientReviewCommentController::class, 'index']);

        Route::post('/reviews/{review}/comments', [ClientReviewCommentController::class, 'store']);
        Route::put('/review-comments/{comment}', [ClientReviewCommentController::class, 'update']);
        Route::delete('/review-comments/{comment}', [ClientReviewCommentController::class, 'destroy']);

        Route::get('/conversations', [ClientConversationController::class, 'index']);
        Route::post('/conversations', [ClientConversationController::class, 'store']);
        Route::get('/conversations/unread-count', [ClientConversationController::class, 'unreadCount']);
        Route::get('/conversations/{conversation}', [ClientConversationController::class, 'show']);
        Route::get('/conversations/{conversation}/messages', [ClientConversationController::class, 'messages']);
        Route::post('/conversations/{conversation}/messages', [ClientConversationController::class, 'sendMessage']);
        Route::post('/conversations/{conversation}/read', [ClientConversationController::class, 'markAsRead']);
        
        Route::get('/payment-methods', [ClientPaymentMethodController::class, 'index']);
        Route::post('/payment-methods', [ClientPaymentMethodController::class, 'store']);
        Route::patch('/payment-methods/{paymentMethod}/default', [ClientPaymentMethodController::class, 'setDefault']);
        Route::delete('/payment-methods/{paymentMethod}', [ClientPaymentMethodController::class, 'destroy']);

        Route::get('/payment-transactions', [ClientPaymentTransactionController::class, 'index']);

        Route::get('/legal-settings', ClientLegalSettingsController::class);

        });
        
        /*
        |--------------------------------------------------------------------------
        | Comentarios de reseñas (públicos)
        |--------------------------------------------------------------------------
        |
        | Visitantes pueden consultar comentarios de reseñas.
        | Usuarios autenticados utilizarán la ruta protegida
        | dentro del grupo auth:sanctum para recibir is_owner.
        |
        */
        Route::get(
            '/client/explore/reviews/{review}/comments',
            [ClientReviewCommentController::class, 'index']
        );
        