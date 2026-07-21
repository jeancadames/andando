<?php

namespace App\Services\Payments;

class PaymentCalculator
{
    /** AndanDO Provider Commissions Module */
    public function commissionRate(?float $commissionRate = null): float
    {
        $rate = $commissionRate
            ?? (float) config('payments.rules.andando_commission_rate', 0.15);

        return max(0, min(1, $rate));
    }

    public function providerRate(?float $commissionRate = null): float
    {
        return 1 - $this->commissionRate($commissionRate);
    }

    public function calculateCommission(float $amount, ?float $commissionRate = null): float
    {
        return round($amount * $this->commissionRate($commissionRate), 2);
    }

    public function calculateProviderAmount(float $amount, ?float $commissionRate = null): float
    {
        return round($amount * $this->providerRate($commissionRate), 2);
    }

    public function calculateChargeBreakdown(float $amount, ?float $commissionRate = null): array
    {
        $resolvedRate = $this->commissionRate($commissionRate);
        $commission = $this->calculateCommission($amount, $resolvedRate);

        return [
            'gross_amount' => round($amount, 2),
            'commission_rate' => $resolvedRate,
            'commission_amount' => $commission,
            'provider_amount' => round($amount - $commission, 2),
        ];
    }

    public function calculateCustomerPolicyRefund(float $amount): array
    {
        $refundPercent = (float) config('payments.rules.customer_policy_refund_percent', 95);
        $refundAmount = round($amount * ($refundPercent / 100), 2);

        return [
            'refund_percent' => $refundPercent,
            'refund_amount' => $refundAmount,
            'retained_amount' => round($amount - $refundAmount, 2),
        ];
    }

    public function calculateFullRefund(float $amount): array
    {
        return [
            'refund_percent' => 100,
            'refund_amount' => round($amount, 2),
            'retained_amount' => 0.00,
        ];
    }

    public function calculateNoRefund(float $amount): array
    {
        return [
            'refund_percent' => 0,
            'refund_amount' => 0.00,
            'retained_amount' => round($amount, 2),
        ];
    }
}
