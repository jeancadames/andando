<?php

namespace App\Console\Commands;

use App\Models\ProviderPayout;
use App\Services\Payments\ProviderPayoutService;
use Illuminate\Console\Command;

class ReleaseProviderPayoutsCommand extends Command
{
    protected $signature = 'payments:release-provider-payouts';

    protected $description = 'Marca como listos para pagar los payouts de proveedores que ya cumplieron su fecha de liberación.';

    public function handle(ProviderPayoutService $providerPayoutService): int
    {
        $payouts = ProviderPayout::query()
            ->where('status', ProviderPayout::STATUS_SCHEDULED)
            ->whereNotNull('scheduled_release_at')
            ->where('scheduled_release_at', '<=', now())
            ->orderBy('scheduled_release_at')
            ->limit(50)
            ->get();

        if ($payouts->isEmpty()) {
            $this->info('No hay payouts listos para liberar.');
            return self::SUCCESS;
        }

        foreach ($payouts as $payout) {
            $this->info("Liberando payout #{$payout->id}");
            $providerPayoutService->markReadyToPay($payout);
        }

        $this->info("Liberados {$payouts->count()} payouts.");

        return self::SUCCESS;
    }
}