<?php

namespace App\Services\Payments;

use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;
use App\Models\ProviderBooking;

/**
 * Servicio de compatibilidad para evitar duplicar la lógica de refunds.
 *
 * Este archivo debe declarar ReconcilePendingPaymentTransactionService
 * porque el nombre del archivo es ReconcilePendingPaymentTransactionService.php.
 *
 * La lógica real de refunds vive en PaymentRefundService.
 */
class ReconcilePendingPaymentTransactionService
{
    public function __construct(
        private readonly PaymentRefundService $paymentRefundService,
    ) {}

    public function refundBooking(
        ProviderBooking $booking,
        PaymentTransaction $transaction,
        float $refundPercent,
        string $reason
    ): PaymentRefund {
        return $this->paymentRefundService->refundBooking(
            booking: $booking,
            transaction: $transaction,
            refundPercent: $refundPercent,
            reason: $reason,
        );
    }
}