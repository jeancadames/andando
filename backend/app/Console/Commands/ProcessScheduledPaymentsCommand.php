<?php

namespace App\Console\Commands;

use App\Models\PaymentTransaction;
use App\Services\Payments\ProcessPaymentTransactionService;
use Illuminate\Console\Command;

class ProcessScheduledPaymentsCommand extends Command
{
    protected $signature = 'payments:process-scheduled-charges';

    protected $description = 'Procesa cobros programados pendientes.';

    public function handle(ProcessPaymentTransactionService $processor): int
    {
        $transactions = PaymentTransaction::query()
            ->where('status', PaymentTransaction::STATUS_SCHEDULED)
            ->whereNotNull('charge_scheduled_at')
            ->where('charge_scheduled_at', '<=', now())
            ->orderBy('charge_scheduled_at')
            ->limit(50)
            ->get();

        if ($transactions->isEmpty()) {
            $this->info('No hay cobros programados pendientes.');
            return self::SUCCESS;
        }

        foreach ($transactions as $transaction) {
            $this->info("Procesando transaction #{$transaction->id}");
            $processor->process($transaction);
        }

        $this->info("Procesadas {$transactions->count()} transacciones.");

        return self::SUCCESS;
    }
}