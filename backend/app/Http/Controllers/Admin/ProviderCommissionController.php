<?php

namespace App\Http\Controllers\Admin;

// AndanDO Provider Commissions Module

use App\Http\Controllers\Controller;
use App\Models\Provider;
use App\Models\ProviderCommissionChange;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class ProviderCommissionController extends Controller
{
    public function index(Request $request): Response
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', Rule::in(['all', 'approved', 'suspended'])],
        ]);

        $filters = [
            'search' => trim((string) ($validated['search'] ?? '')),
            'status' => (string) ($validated['status'] ?? 'all'),
        ];

        $query = Provider::query()
            ->with([
                'user:id,name,email',
                'latestCommissionChange.changedBy:id,name,email',
            ])
            ->whereIn('status', ['approved', 'suspended']);

        if ($filters['search'] !== '') {
            $search = $filters['search'];

            $query->where(function (Builder $builder) use ($search) {
                if (ctype_digit($search)) {
                    $builder->orWhereKey((int) $search);
                }

                $builder
                    ->orWhere('business_name', 'like', "%{$search}%")
                    ->orWhere('rnc', 'like', "%{$search}%")
                    ->orWhereHas('user', fn (Builder $user) => $user
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%"));
            });
        }

        if ($filters['status'] !== 'all') {
            $query->where('status', $filters['status']);
        }

        return Inertia::render('Commissions/Index', [
            'providers' => $query
                ->orderBy('business_name')
                ->paginate(20)
                ->withQueryString(),
            'filters' => $filters,
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

    public function update(Request $request, Provider $provider): RedirectResponse
    {
        if (! in_array($provider->status, ['approved', 'suspended'], true)) {
            return back()->with(
                'error',
                'La comisión se asigna al aprobar el afiliado.'
            );
        }

        $validated = $request->validate([
            'commission_percent' => ['required', 'numeric', 'min:0', 'max:100'],
        ]);

        $newRate = round((float) $validated['commission_percent'] / 100, 4);

        DB::transaction(function () use ($request, $provider, $newRate) {
            $oldRate = $provider->commission_rate;

            $provider->update([
                'commission_rate' => $newRate,
            ]);

            ProviderCommissionChange::create([
                'provider_id' => $provider->id,
                'changed_by_user_id' => $request->user()->id,
                'old_rate' => $oldRate,
                'new_rate' => $newRate,
                'source' => ProviderCommissionChange::SOURCE_ADMIN_UPDATE,
            ]);
        });

        return back()->with(
            'success',
            'Comisión de ' . number_format(
                (float) $validated['commission_percent'],
                2
            ) . '% asignada a ' . $provider->business_name . '.'
        );
    }
}
