<?php

namespace App\Console\Commands;

use App\Models\PaymentTransaction;
use App\Services\Payments\ReconcilePendingPaymentTransactionService;
use Illuminate\Console\Command;

class ReconcilePendingPaymentsCommand extends Command
{
    protected $signature = 'payments:reconcile-pending-verifications';

    protected $description = 'Verifica con Azul transacciones en estado pending_verification.';

    public function handle(ReconcilePendingPaymentTransactionService $reconciler): int
    {
        $transactions = PaymentTransaction::query()
            ->where('status', PaymentTransaction::STATUS_PENDING_VERIFICATION)
            ->orderBy('updated_at')
            ->limit(50)
            ->get();

        if ($transactions->isEmpty()) {
            $this->info('No hay transacciones pendientes de verificación.');
            return self::SUCCESS;
        }

        foreach ($transactions as $transaction) {
            $this->info("Verificando transaction #{$transaction->id}");
            $reconciler->reconcile($transaction);
        }

        $this->info("Verificadas {$transactions->count()} transacciones.");

        return self::SUCCESS;
    }
}