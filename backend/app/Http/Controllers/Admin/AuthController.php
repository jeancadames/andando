<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Autenticación del panel. No hay registro: solo login y logout.
 *
 * El attempt incluye type => 'admin', así que aunque alguien tenga
 * credenciales válidas de cliente o proveedor, no podrá entrar al panel.
 */
class AuthController extends Controller
{
    public function create(): Response
    {
        return Inertia::render('Auth/Login');
    }

    public function store(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $ok = Auth::attempt([
            'email' => $credentials['email'],
            'password' => $credentials['password'],
            'type' => 'admin',
        ], $request->boolean('remember'));

        if (! $ok) {
            throw ValidationException::withMessages([
                'email' => 'Las credenciales no son válidas.',
            ]);
        }

        $request->session()->regenerate();

        return redirect()->intended(route('admin.dashboard'));
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::guard('web')->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }
}
