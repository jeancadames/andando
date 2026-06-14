<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BookingClaim;
use App\Models\Provider;
use App\Models\ProviderExperience;
use App\Models\ProviderVerificationRequest;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Dashboard', [
            'stats' => [
                'pendingRequests' => ProviderVerificationRequest::where('status', 'pending')->count(),
                'approvedProviders' => Provider::where('status', 'approved')->count(),
                'pendingClaims' => BookingClaim::whereIn('status', ['pending', 'provider_replied'])->count(),
                'activeExperiences' => ProviderExperience::where('is_active', true)->count(),
                'inactiveExperiences' => ProviderExperience::where('is_active', false)->count(),
            ],

            // Últimas solicitudes pendientes para acceso rápido.
            'recentRequests' => ProviderVerificationRequest::with([
                'provider:id,business_name,city,province,provider_business_type_id',
                'provider.businessType:id,name',
            ])
                ->where('status', 'pending')
                ->latest('submitted_at')
                ->limit(5)
                ->get(),

            // Últimos reclamos abiertos.
            'recentClaims' => BookingClaim::with([
                'provider:id,business_name',
                'user:id,name',
            ])
                ->whereIn('status', ['pending', 'provider_replied'])
                ->latest()
                ->limit(5)
                ->get(),
        ]);
    }
}
