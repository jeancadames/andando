<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class CompleteSocialLegalOnboardingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'birth_date' => [
                'required',
                'date_format:Y-m-d',
                'before_or_equal:' . now()
                    ->subYears(18)
                    ->format('Y-m-d'),
            ],

            'terms_document_id' => [
                'required',
                'integer',
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
            'birth_date.required' =>
                'La fecha de nacimiento es obligatoria.',

            'birth_date.date_format' =>
                'La fecha de nacimiento debe tener el formato AAAA-MM-DD.',

            'birth_date.before_or_equal' =>
                'Debes tener al menos 18 años para utilizar AndanDO.',

            'terms_document_id.required' =>
                'Debes indicar la versión vigente de los Términos y Condiciones.',

            'terms_document_id.integer' =>
                'El documento de Términos y Condiciones no es válido.',

            'terms_checksum.required' =>
                'La verificación de los Términos y Condiciones es obligatoria.',

            'terms_checksum.size' =>
                'La verificación de los Términos y Condiciones no es válida.',

            'accept_terms.required' =>
                'Debes aceptar los Términos y Condiciones.',

            'accept_terms.accepted' =>
                'Debes aceptar los Términos y Condiciones.',

            'privacy_document_id.required' =>
                'Debes indicar la versión vigente de la Política de Privacidad.',

            'privacy_document_id.integer' =>
                'El documento de Política de Privacidad no es válido.',

            'privacy_checksum.required' =>
                'La verificación de la Política de Privacidad es obligatoria.',

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
        $birthDate = $this->input('birth_date');

        $this->merge([
            'birth_date' => is_string($birthDate)
                ? trim($birthDate)
                : $birthDate,

            'terms_checksum' => strtolower(
                trim((string) $this->input('terms_checksum', ''))
            ),

            'privacy_checksum' => strtolower(
                trim((string) $this->input('privacy_checksum', ''))
            ),
        ]);
    }
}