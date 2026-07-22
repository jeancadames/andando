<?php

namespace App\Http\Requests\Provider;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/// Valida el registro completo del proveedor.
///
/// Esta request recibe:
/// - datos personales
/// - datos del negocio
/// - documentos de verificación
/// - documentos legales vigentes
/// - aceptación de términos, estándares y privacidad
class ProviderRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            /*
             * Paso 1: datos personales.
             */
            'full_name' => [
                'required',
                'string',
                'max:150',
            ],
            'email' => [
                'required',
                'email',
                'max:150',
                'unique:users,email',
            ],
            'phone' => [
                'required',
                'string',
                'max:30',
            ],
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
            ],

            /*
             * Paso 2: datos del negocio.
             */
            'business_name' => [
                'required',
                'string',
                'max:180',
            ],
            'business_type_slug' => [
                'required',
                'string',
                Rule::exists('provider_business_types', 'slug')
                    ->where('is_active', true),
            ],
            'rnc' => [
                'required',
                'string',
                'max:30',
                'unique:providers,rnc',
            ],
            'address' => [
                'required',
                'string',
                'max:1000',
            ],
            'city' => [
                'required',
                'string',
                'max:100',
            ],
            'province' => [
                'required',
                'string',
                'max:100',
            ],

            /*
             * Paso 3: documentos de verificación.
             *
             * Laravel expresa el tamaño máximo en KB.
             * 5120 KB = 5 MB.
             */
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

            /*
             * Paso 4: aceptación legal.
             */
            'accept_terms' => [
                'required',
                'accepted',
            ],
            'accept_standards' => [
                'required',
                'accepted',
            ],
            'accept_privacy' => [
                'required',
                'accepted',
            ],

            /*
             * Términos para afiliados.
             */
            'terms_document_id' => [
                'required',
                'integer',
                'exists:legal_documents,id',
            ],
            'terms_document_checksum' => [
                'required',
                'string',
                'size:64',
            ],

            /*
             * Estándares de publicación, operación y seguridad.
             */
            'standards_document_id' => [
                'required',
                'integer',
                'exists:legal_documents,id',
            ],
            'standards_document_checksum' => [
                'required',
                'string',
                'size:64',
            ],

            /*
             * Política de privacidad.
             */
            'privacy_document_id' => [
                'required',
                'integer',
                'exists:legal_documents,id',
            ],
            'privacy_document_checksum' => [
                'required',
                'string',
                'size:64',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'password.confirmed' =>
                'Las contraseñas no coinciden.',

            'identity_card.required' =>
                'La cédula de identidad es obligatoria.',

            'rnc_certificate.required' =>
                'El certificado RNC es obligatorio.',

            'accept_terms.accepted' =>
                'Debes aceptar los Términos y Condiciones para Afiliados.',

            'accept_standards.accepted' =>
                'Debes aceptar los Estándares de Publicación, Operación y Seguridad.',

            'accept_privacy.accepted' =>
                'Debes confirmar que has leído la Política de Privacidad.',

            'terms_document_id.required' =>
                'No se pudo identificar el documento de términos.',

            'terms_document_id.exists' =>
                'El documento de términos indicado no es válido.',

            'terms_document_checksum.required' =>
                'No se pudo verificar el contenido de los términos.',

            'terms_document_checksum.size' =>
                'La verificación de los términos no es válida.',

            'standards_document_id.required' =>
                'No se pudo identificar el documento de estándares.',

            'standards_document_id.exists' =>
                'El documento de estándares indicado no es válido.',

            'standards_document_checksum.required' =>
                'No se pudo verificar el contenido de los estándares.',

            'standards_document_checksum.size' =>
                'La verificación de los estándares no es válida.',

            'privacy_document_id.required' =>
                'No se pudo identificar la Política de Privacidad.',

            'privacy_document_id.exists' =>
                'La Política de Privacidad indicada no es válida.',

            'privacy_document_checksum.required' =>
                'No se pudo verificar el contenido de la Política de Privacidad.',

            'privacy_document_checksum.size' =>
                'La verificación de la Política de Privacidad no es válida.',
        ];
    }
}