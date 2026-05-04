<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\CustomerRegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/**
 * Class CustomerAuthController
 *
 * Este controlador maneja la autenticación de clientes.
 *
 * RESPONSABILIDADES:
 * - Recibir la request validada
 * - Ejecutar lógica de negocio
 * - Crear usuario
 * - Generar token
 * - Responder JSON
 *
 * IMPORTANTE:
 * No valida datos (eso lo hace el Request)
 */
class CustomerAuthController extends Controller
{
    /**
     * Registrar un nuevo cliente
     *
     * Flujo:
     * 1. Recibe datos validados
     * 2. Inicia transacción
     * 3. Crea usuario
     * 4. Genera token Sanctum
     * 5. Devuelve respuesta
     */
    public function register(CustomerRegisterRequest $request): JsonResponse
    {
        // Datos ya validados por el Request
        $validated = $request->validated();

        /**
         * DB::transaction asegura que:
         * - Si algo falla, TODO se revierte
         * - No quedan datos inconsistentes
         */
        $result = DB::transaction(function () use ($validated) {

            /**
             * Crear usuario en base de datos
             */
            $user = User::query()->create([
                // Guardamos full_name en campo name
                'name' => $validated['full_name'],

                // Normalizamos email a minúsculas
                'email' => strtolower($validated['email']),

                // Teléfono opcional
                'phone' => $validated['phone'] ?? null,

                // Tipo de usuario (IMPORTANTE)
                'type' => 'customer',

                // Hash de contraseña (NUNCA guardar texto plano)
                'password' => Hash::make($validated['password']),
            ]);

            /**
             * Crear token de autenticación
             * Este token se usará en todas las requests futuras
             */
            $token = $user->createToken('customer-mobile')->plainTextToken;

            return [
                'user' => $user,
                'token' => $token,
            ];
        });

        /**
         * Respuesta estándar hacia Flutter
         */
        return response()->json([
            'message' => 'Cuenta de cliente creada correctamente.',

            // Token para autenticación
            'token' => $result['token'],

            // Datos del usuario
            'user' => [
                'id' => $result['user']->id,
                'name' => $result['user']->name,
                'email' => $result['user']->email,
                'phone' => $result['user']->phone,
                'type' => $result['user']->type,
            ],
        ], 201);
    }
}