<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Provider;
use App\Services\ProviderSuspensionService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;

/**
 * Gestión del estado de cuenta de un proveedor (afiliado).
 *
 *  - suspend:    approved -> suspended  + cancela toda su operación + revoca tokens
 *  - reactivate: suspended -> approved  + deja sus experiencias en borrador
 */
class ProviderController extends Controller
{
    public function suspend(Provider $provider, ProviderSuspensionService $service): RedirectResponse
    {
        if ($provider->status !== 'approved') {
            return back()->with('error', 'Solo se puede suspender a un afiliado aprobado.');
        }

        DB::transaction(function () use ($provider, $service) {
            $provider->update([
                'status' => 'suspended',
                'suspended_at' => now(),
            ]);

            // Cascada: experiencias, salidas y reservas pendientes -> canceladas.
            $service->cancelProviderOperations($provider);

            // Cierra su sesión en la app: invalida todos sus tokens de acceso.
            $provider->user?->tokens()->delete();
        });

        return back()->with(
            'success',
            'Afiliado suspendido. Se cancelaron sus experiencias, salidas y reservas pendientes, y se revocó su acceso a la app.'
        );
    }

    public function reactivate(Provider $provider, ProviderSuspensionService $service): RedirectResponse
    {
        if ($provider->status !== 'suspended') {
            return back()->with('error', 'Solo se puede reactivar a un afiliado suspendido.');
        }

        DB::transaction(function () use ($provider, $service) {
            $provider->update([
                'status' => 'approved',
                'suspended_at' => null,
            ]);

            // Las experiencias rechazadas vuelven a borrador para republicar.
            // Salidas y reservas canceladas NO se revierten.
            $service->restoreProviderExperiencesToDraft($provider);
        });

        return back()->with(
            'success',
            'Afiliado reactivado. Sus experiencias quedaron en borrador para que las publique de nuevo.'
        );
    }
}
