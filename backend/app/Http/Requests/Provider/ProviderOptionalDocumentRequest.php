<?php

namespace App\Http\Requests\Provider;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class ProviderOptionalDocumentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $fileRules = [
            'nullable',
            'file',
            'max:5120',
            'mimes:pdf,jpg,jpeg,png,webp',
        ];

        return [
            'business_license' => $fileRules,
            'insurance_policy' => $fileRules,
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if (
                ! $this->hasFile('business_license') &&
                ! $this->hasFile('insurance_policy')
            ) {
                $validator->errors()->add(
                    'documents',
                    'Selecciona al menos un documento opcional.'
                );
            }
        });
    }

    public function messages(): array
    {
        return [
            '*.max' => 'Cada documento puede pesar un máximo de 5MB.',
            '*.mimes' =>
                'Los documentos deben ser PDF, JPG, PNG o WEBP.',
        ];
    }
}
