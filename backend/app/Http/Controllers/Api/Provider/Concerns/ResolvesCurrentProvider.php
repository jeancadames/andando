<?php

namespace App\Http\Controllers\Api\Provider\Concerns;

use App\Models\Provider;
use Illuminate\Http\Request;

trait ResolvesCurrentProvider
{
    protected function currentProvider(Request $request): Provider
    {
        $user = $request->user();

        $provider = $user?->provider;

        if (! $provider) {
            abort(response()->json([
                'message' => 'Este usuario no tiene un perfil de proveedor asociado.',
            ], 403));
        }

        return $provider;
    }
}