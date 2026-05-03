<?php

namespace App\Http\Requests\Provider;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/// Valida el registro completo del proveedor.
///
/// Esta request recibe:
/// - datos personales
/// - datos del negocio
/// - documentos
/// - aceptación de términos
class ProviderRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        /// Por ahora cualquier visitante puede registrarse como proveedor.
        return true;
    }

    public function rules(): array
    {
        return [
            /// Paso 1
            'full_name' => ['required', 'string', 'max:150'],
            'email' => ['required', 'email', 'max:150', 'unique:users,email'],
            'phone' => ['required', 'string', 'max:30'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],

            /// Paso 2
            'business_name' => ['required', 'string', 'max:180'],
            'business_type_slug' => [
                'required',
                'string',
                Rule::exists('provider_business_types', 'slug')
                    ->where('is_active', true),
            ],
            'rnc' => ['required', 'string', 'max:30', 'unique:providers,rnc'],
            'address' => ['required', 'string', 'max:1000'],
            'city' => ['required', 'string', 'max:100'],
            'province' => ['required', 'string', 'max:100'],

            /// Paso 3
            ///
            /// Máximo 5MB.
            /// Laravel usa KB, entonces 5120 = 5MB.
            'identity_card' => [
                'required',
                'file',
                'max:5120',
                'mimes:pdf,jpg,jpeg,png,webp',
            ],
            'rnc_certificate' => [
                'required',
                'file',
                'max:5120',
                'mimes:pdf,jpg,jpeg,png,webp',
            ],
            'business_license' => [
                'nullable',
                'file',
                'max:5120',
                'mimes:pdf,jpg,jpeg,png,webp',
            ],

            /// Paso 4
            'accept_terms' => ['required', 'accepted'],
            'accept_privacy' => ['required', 'accepted'],
        ];
    }

    public function messages(): array
    {
        return [
            'password.confirmed' => 'Las contraseñas no coinciden.',
            'identity_card.required' => 'La cédula de identidad es obligatoria.',
            'rnc_certificate.required' => 'El certificado RNC es obligatorio.',
            'accept_terms.accepted' => 'Debes aceptar los términos y condiciones.',
            'accept_privacy.accepted' => 'Debes aceptar la política de privacidad.',
        ];
    }
}