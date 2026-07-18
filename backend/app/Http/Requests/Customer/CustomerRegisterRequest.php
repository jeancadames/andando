<?php

namespace App\Http\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;

class CustomerRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'full_name' => [
                'required',
                'string',
                'min:2',
                'max:255',
            ],

            'email' => [
                'required',
                'email',
                'max:255',
                'unique:users,email',
            ],

            'phone' => [
                'nullable',
                'string',
                'max:30',
            ],

            'birth_date' => [
                'required',
                'date_format:Y-m-d',
                'before_or_equal:' . now()
                    ->subYears(18)
                    ->toDateString(),
            ],

            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
            ],

            'terms_document_id' => [
                'required',
                'integer',
                'exists:legal_documents,id',
            ],

            'terms_checksum' => [
                'required',
                'string',
                'size:64',
            ],

            'accept_terms' => [
                'required',
                'accepted',
            ],

            'privacy_document_id' => [
                'required',
                'integer',
                'exists:legal_documents,id',
            ],

            'privacy_checksum' => [
                'required',
                'string',
                'size:64',
            ],

            'privacy_acknowledged' => [
                'required',
                'accepted',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'full_name.required' =>
                'El nombre completo es obligatorio.',

            'full_name.min' =>
                'El nombre debe tener al menos 2 caracteres.',

            'email.required' =>
                'El correo es obligatorio.',

            'email.email' =>
                'El correo no tiene un formato válido.',

            'email.unique' =>
                'Este correo ya está registrado.',

            'birth_date.required' =>
                'La fecha de nacimiento es obligatoria.',

            'birth_date.date_format' =>
                'La fecha de nacimiento debe tener el formato AAAA-MM-DD.',

            'birth_date.before_or_equal' =>
                'Debes tener al menos 18 años para crear una cuenta en AndanDO.',

            'password.required' =>
                'La contraseña es obligatoria.',

            'password.min' =>
                'La contraseña debe tener al menos 8 caracteres.',

            'password.confirmed' =>
                'Las contraseñas no coinciden.',

            'terms_document_id.required' =>
                'No se pudo identificar la versión de los Términos y Condiciones.',

            'terms_document_id.exists' =>
                'La versión de los Términos y Condiciones indicada no existe.',

            'terms_checksum.required' =>
                'No se recibió la verificación de los Términos y Condiciones.',

            'terms_checksum.size' =>
                'La verificación de los Términos y Condiciones no es válida.',

            'accept_terms.required' =>
                'Debes aceptar los Términos y Condiciones.',

            'accept_terms.accepted' =>
                'Debes aceptar los Términos y Condiciones.',

            'privacy_document_id.required' =>
                'No se pudo identificar la versión de la Política de Privacidad.',

            'privacy_document_id.exists' =>
                'La versión de la Política de Privacidad indicada no existe.',

            'privacy_checksum.required' =>
                'No se recibió la verificación de la Política de Privacidad.',

            'privacy_checksum.size' =>
                'La verificación de la Política de Privacidad no es válida.',

            'privacy_acknowledged.required' =>
                'Debes confirmar que leíste la Política de Privacidad.',

            'privacy_acknowledged.accepted' =>
                'Debes confirmar que leíste la Política de Privacidad.',
        ];
    }

    protected function prepareForValidation(): void
    {
        $email = $this->input('email');

        if (is_string($email)) {
            $this->merge([
                'email' => strtolower(trim($email)),
            ]);
        }

        $fullName = $this->input('full_name');

        if (is_string($fullName)) {
            $this->merge([
                'full_name' => trim($fullName),
            ]);
        }

        $phone = $this->input('phone');

        if (is_string($phone)) {
            $phone = trim($phone);

            $this->merge([
                'phone' => $phone === ''
                    ? null
                    : $phone,
            ]);
        }
    }
}