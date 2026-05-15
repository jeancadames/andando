<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\Provider;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * LoginController
 *
 * Login general de AndanDO.
 *
 * Este controlador permite iniciar sesión con:
 * - cuentas de cliente.
 * - cuentas de afiliado/proveedor.
 *
 * Flutter llamará:
 *
 * POST /api/auth/login
 *
 * Y este endpoint responderá con:
 * - token Sanctum.
 * - datos del usuario.
 * - datos del provider si el usuario es afiliado/proveedor.
 */
class LoginController extends Controller
{
    /**
     * Ejecuta el login general.
     *
     * Este método es __invoke porque en routes/api.php usamos:
     *
     * Route::post('/auth/login', LoginController::class);
     *
     * Cuando se registra un controller así, Laravel exige que exista
     * este método __invoke().
     */
    public function __invoke(Request $request): JsonResponse
    {
        /*
        |--------------------------------------------------------------------------
        | Validación
        |--------------------------------------------------------------------------
        |
        | Validamos que el request tenga email y password.
        | Si falta algo, Laravel responde automáticamente con 422.
        */
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        /*
        |--------------------------------------------------------------------------
        | Buscar usuario
        |--------------------------------------------------------------------------
        |
        | Normalizamos el email a minúsculas para evitar problemas si el usuario
        | escribe el correo con alguna mayúscula.
        */
        $user = User::query()
            ->where('email', strtolower($validated['email']))
            ->first();

        /*
        |--------------------------------------------------------------------------
        | Validar credenciales
        |--------------------------------------------------------------------------
        |
        | No indicamos si falló el email o la contraseña por separado.
        | Esto es más seguro.
        */
        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Las credenciales no son correctas.'],
            ]);
        }

        /*
        |--------------------------------------------------------------------------
        | Detectar si el usuario es afiliado/proveedor
        |--------------------------------------------------------------------------
        |
        | Si existe un registro en providers asociado a este user_id,
        | entonces tratamos la cuenta como provider.
        |
        | Lo hacemos con Provider::query() para no depender únicamente
        | de la relación del modelo User.
        */
        $provider = Provider::query()
            ->where('user_id', $user->id)
            ->first();

        /*
        |--------------------------------------------------------------------------
        | Crear token Sanctum
        |--------------------------------------------------------------------------
        |
        | Este token lo guardará Flutter localmente y se usará luego en requests
        | protegidas con:
        |
        | Authorization: Bearer <token>
        */
        $tokenName = $provider ? 'provider-mobile' : 'customer-mobile';

        $token = $user->createToken($tokenName)->plainTextToken;

        /*
        |--------------------------------------------------------------------------
        | Determinar tipo de usuario
        |--------------------------------------------------------------------------
        |
        | Si tiene provider, devolvemos provider.
        | Si no, usamos el campo users.type.
        | Si users.type está vacío, asumimos customer.
        */
        $userType = $provider
            ? 'provider'
            : ($user->type ?: 'customer');

        /*
        |--------------------------------------------------------------------------
        | Respuesta estándar para Flutter
        |--------------------------------------------------------------------------
        |
        | Flutter podrá decidir:
        |
        | customer -> /client/explore
        | provider approved -> /provider/dashboard
        | provider pending/rejected/suspended -> /provider/verification-pending
        */
        return response()->json([
            'message' => 'Inicio de sesión correcto.',
            'token' => $token,

            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone ?? null,
                'type' => $userType,
            ],

            'provider' => $provider ? [
                'id' => $provider->id,
                'business_name' => $provider->business_name,
                'status' => $provider->status,
                'rejection_reason' => $provider->rejection_reason,
            ] : null,
        ]);
    }
}