<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ProviderExperience;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Administración de experiencias.
 *
 * El admin no crea experiencias (eso lo hace el afiliado desde la app).
 * Aquí puede desactivarlas (is_active = false) cuando hay un problema,
 * volverlas a activar, o rechazarlas (status = 'rejected').
 */
class ExperienceController extends Controller
{
    public function index(Request $request): Response
    {
        $search = $request->string('search')->toString();
        $active = $request->string('active', 'all')->toString();
        $status = $request->string('status', 'all')->toString();

        $query = ProviderExperience::query()
            ->with(['provider:id,business_name'])
            ->withCount(['bookings', 'reviews']);

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('location', 'like', "%{$search}%")
                    ->orWhere('province', 'like', "%{$search}%");
            });
        }

        if ($active === 'active') {
            $query->where('is_active', true);
        } elseif ($active === 'inactive') {
            $query->where('is_active', false);
        }

        if (in_array($status, ['draft', 'published', 'paused', 'rejected'], true)) {
            $query->where('status', $status);
        }

        $experiences = $query
            ->latest()
            ->paginate(15)
            ->withQueryString();

        return Inertia::render('Experiences/Index', [
            'experiences' => $experiences,
            'filters' => [
                'search' => $search,
                'active' => $active,
                'status' => $status,
            ],
        ]);
    }

    public function show(ProviderExperience $experience): Response
    {
        $experience->load([
            'provider:id,business_name,city,province',
            'provider.user:id,name,email',
            'photos',
            'coverPhoto',
        ]);
        $experience->loadCount(['bookings', 'reviews']);

        return Inertia::render('Experiences/Show', [
            'experience' => $experience,
        ]);
    }

    public function toggleActive(ProviderExperience $experience): RedirectResponse
    {
        $experience->update([
            'is_active' => ! $experience->is_active,
        ]);

        $msg = $experience->is_active
            ? 'Experiencia activada.'
            : 'Experiencia desactivada.';

        return back()->with('success', $msg);
    }

    public function reject(Request $request, ProviderExperience $experience): RedirectResponse
    {
        $experience->update([
            'status' => 'rejected',
            'is_active' => false,
        ]);

        return back()->with('success', 'Experiencia rechazada y desactivada.');
    }
}
