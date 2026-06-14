<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BookingClaim;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Reclamos de reservas (booking_claims).
 *
 * El admin puede revisar el reclamo, ver la reserva asociada y
 * marcarlo como resuelto o rechazado. provider_response es la
 * respuesta del afiliado y se muestra solo como referencia.
 */
class ClaimController extends Controller
{
    public function index(Request $request): Response
    {
        $status = $request->string('status', 'all')->toString();
        $allowed = ['pending', 'provider_replied', 'resolved', 'rejected'];

        $query = BookingClaim::query()
            ->with([
                'provider:id,business_name',
                'user:id,name,email',
                'booking:id,booking_code,booking_date,provider_experience_id',
                'booking.experience:id,title',
            ]);

        if (in_array($status, $allowed, true)) {
            $query->where('status', $status);
        }

        $claims = $query
            ->latest()
            ->paginate(15)
            ->withQueryString();

        return Inertia::render('Claims/Index', [
            'claims' => $claims,
            'filters' => ['status' => $status],
            'counts' => [
                'open' => BookingClaim::whereIn('status', ['pending', 'provider_replied'])->count(),
                'resolved' => BookingClaim::where('status', 'resolved')->count(),
                'rejected' => BookingClaim::where('status', 'rejected')->count(),
            ],
        ]);
    }

    public function show(BookingClaim $claim): Response
    {
        $claim->load([
            'provider:id,business_name,city,province',
            'provider.user:id,name,email,phone',
            'user:id,name,email,phone',
            'booking',
            'booking.experience:id,title,location,province',
            'booking.schedule:id,starts_at,ends_at',
        ]);

        return Inertia::render('Claims/Show', [
            'claim' => $claim,
        ]);
    }

    public function resolve(Request $request, BookingClaim $claim): RedirectResponse
    {
        if (in_array($claim->status, ['resolved', 'rejected'], true)) {
            return back()->with('error', 'Este reclamo ya fue cerrado.');
        }

        $claim->update([
            'status' => 'resolved',
            'resolved_at' => now(),
        ]);

        return back()->with('success', 'Reclamo marcado como resuelto.');
    }

    public function reject(Request $request, BookingClaim $claim): RedirectResponse
    {
        if (in_array($claim->status, ['resolved', 'rejected'], true)) {
            return back()->with('error', 'Este reclamo ya fue cerrado.');
        }

        $claim->update([
            'status' => 'rejected',
            'resolved_at' => now(),
        ]);

        return back()->with('success', 'Reclamo rechazado.');
    }
}
