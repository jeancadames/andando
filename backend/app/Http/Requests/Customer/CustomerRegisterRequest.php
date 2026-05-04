<?php

namespace App\Http\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Class CustomerRegisterRequest
 *
 * Este Request se encarga de:
 * - Validar los datos que vienen desde Flutter
 * - Centralizar reglas de validación
 * - Evitar lógica en el Controller
 *
 * IMPORTANTE:
 * Flutter SOLO envía datos, Laravel decide si son válidos.
 */
class CustomerRegisterRequest extends FormRequest
{
    /**
     * Autoriza la petición.
     * Aquí podrías validar permisos si fuera necesario.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Reglas de validación.
     *
     * Estas reglas aseguran:
     * - Integridad de datos
     * - Consistencia del sistema
     */
    public function rules(): array
    {
        return [
            // Nombre completo obligatorio, mínimo 2 caracteres
            'full_name' => ['required', 'string', 'min:2', 'max:255'],

            // Email obligatorio, único en tabla users
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],

            // Teléfono opcional
            'phone' => ['nullable', 'string', 'max:30'],

            // Contraseña obligatoria + confirmación
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ];
    }

    /**
     * Mensajes personalizados para errores.
     */
    public function messages(): array
    {
        return [
            'full_name.required' => 'El nombre completo es obligatorio.',
            'full_name.min' => 'El nombre debe tener al menos 2 caracteres.',

            'email.required' => 'El correo es obligatorio.',
            'email.email' => 'El correo no tiene un formato válido.',
            'email.unique' => 'Este correo ya está registrado.',

            'password.required' => 'La contraseña es obligatoria.',
            'password.min' => 'La contraseña debe tener al menos 8 caracteres.',
            'password.confirmed' => 'Las contraseñas no coinciden.',
        ];
    }
}