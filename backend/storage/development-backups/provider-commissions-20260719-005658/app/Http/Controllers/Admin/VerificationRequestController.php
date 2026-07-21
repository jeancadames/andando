<?php

namespace App\Http\Controllers\Admin;

use App\Notifications\Auth\ProviderApprovedNotification;
use App\Notifications\Auth\ProviderRejectedNotification;

use App\Http\Controllers\Controller;
use App\Models\ProviderVerificationRequest;
use App\Models\ProviderCommissionChange;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Gestión de solicitudes de afiliados (proveedores).
 *
 * El flujo real vive en dos tablas:
 *  - provider_verification_requests: la solicitud que se revisa.
 *  - providers: el estado "vigente" del proveedor.
 *
 * Al aprobar/rechazar se actualizan ambas dentro de una transacción.
 */
class VerificationRequestController extends Controller
{
    public function index(Request $request): Response
    {
        $status = $request->string('status', 'pending')->toString();

        $query = ProviderVerificationRequest::query()
            ->with([
                'provider:id,user_id,business_name,rnc,city,province,status,provider_business_type_id,commission_rate',
                'provider.user:id,name,email,phone',
                'provider.businessType:id,name',
            ])
            ->withCount('documents');

        if (in_array($status, ['pending', 'approved', 'rejected'], true)) {
            $query->where('status', $status);
        }

        $requests = $query
            ->latest('submitted_at')
            ->latest('id')
            ->paginate(15)
            ->withQueryString();

        return Inertia::render('Affiliates/Index', [
            'requests' => $requests,
            'filters' => ['status' => $status],
            'counts' => [
                'pending' => ProviderVerificationRequest::where('status', 'pending')->count(),
                'approved' => ProviderVerificationRequest::where('status', 'approved')->count(),
                'rejected' => ProviderVerificationRequest::where('status', 'rejected')->count(),
            ],
        ]);
    }

    public function show(ProviderVerificationRequest $verificationRequest): Response
    {
        $verificationRequest->load([
            'provider:id,user_id,business_name,rnc,address,city,province,status,rejection_reason,approved_at,rejected_at,provider_business_type_id,commission_rate',
            'provider.user:id,name,email,phone',
            'provider.businessType:id,name,slug',
            'documents',
            'reviewer:id,name',
        ]);

        return Inertia::render('Affiliates/Show', [
            'request' => $verificationRequest,
            'defaultCommissionPercent' => round(
                max(
                    0,
                    min(
                        1,
                        (float) config('payments.rules.andando_commission_rate', 0.15)
                    )
                ) * 100,
                2
            ),
        ]);
    }

    public function approve(Request $request, ProviderVerificationRequest $verificationRequest): RedirectResponse
    {
        if ($verificationRequest->status !== 'pending') {
            return back()->with('error', 'Esta solicitud ya fue revisada.');
        }

        $validated = $request->validate([
            'commission_percent' => ['required', 'numeric', 'min:0', 'max:100'],
        ]);

        DB::transaction(function () use ($request, $verificationRequest, $validated) {
            $newCommissionRate = round(
                (float) $validated['commission_percent'] / 100,
                4
            );
            $oldCommissionRate = $verificationRequest->provider?->commission_rate;

            $verificationRequest->update([
                'status' => 'approved',
                'reviewed_by' => $request->user()->id,
                'reviewed_at' => now(),
                'rejection_reason' => null,
            ]);

            $verificationRequest->provider?->update([
                'status' => 'approved',
                'commission_rate' => $newCommissionRate,
                'approved_at' => now(),
                'rejected_at' => null,
                'rejection_reason' => null,
            ]);

            if ($verificationRequest->provider) {
                ProviderCommissionChange::create([
                    'provider_id' => $verificationRequest->provider->id,
                    'changed_by_user_id' => $request->user()->id,
                    'old_rate' => $oldCommissionRate,
                    'new_rate' => $newCommissionRate,
                    'source' => ProviderCommissionChange::SOURCE_APPROVAL,
                ]);
            }

            $verificationRequest->documents()->update([
                'status' => 'approved',
                'reviewed_at' => now(),
            ]);
        });

        $verificationRequest->loadMissing([
            'provider.user',
            'provider.businessType',
        ]);

        $verificationRequest->provider?->user?->notify(
            new ProviderApprovedNotification($verificationRequest)
        );

        return redirect()
            ->route('admin.affiliates.show', $verificationRequest)
            ->with('success', 'Afiliado aprobado correctamente.');
    }

    public function reject(Request $request, ProviderVerificationRequest $verificationRequest): RedirectResponse
    {
        $data = $request->validate([
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ]);

        if ($verificationRequest->status !== 'pending') {
            return back()->with('error', 'Esta solicitud ya fue revisada.');
        }

        DB::transaction(function () use ($request, $verificationRequest, $data) {
            $verificationRequest->update([
                'status' => 'rejected',
                'reviewed_by' => $request->user()->id,
                'reviewed_at' => now(),
                'rejection_reason' => $data['reason'],
            ]);

            $verificationRequest->provider?->update([
                'status' => 'rejected',
                'rejected_at' => now(),
                'rejection_reason' => $data['reason'],
            ]);
        });

        $verificationRequest->loadMissing([
            'provider.user',
            'provider.businessType',
        ]);

        $verificationRequest->provider?->user?->notify(
            new ProviderRejectedNotification($verificationRequest)
        );

        return redirect()
            ->route('admin.affiliates.show', $verificationRequest)
            ->with('success', 'Solicitud rechazada.');
    }
}
