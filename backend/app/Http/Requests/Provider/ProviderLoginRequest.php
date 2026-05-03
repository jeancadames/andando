<?php

namespace App\Http\Requests\Provider;

use Illuminate\Foundation\Http\FormRequest;

/// Valida el login del proveedor.
class ProviderLoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ];
    }
}