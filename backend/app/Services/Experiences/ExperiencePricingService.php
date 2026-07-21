<?php

namespace App\Services\Experiences;

use App\Models\ProviderExperience;

class ExperiencePricingService
{
    public const MIN_DISCOUNT_PERCENTAGE = 1.0;
    public const MAX_DISCOUNT_PERCENTAGE = 90.0;

    /**
     * Calcula el precio efectivo de una experiencia sin confiar en el cliente.
     *
     * @return array{
     *     has_discount: bool,
     *     original_price: float,
     *     discount_percentage: float,
     *     discount_amount: float,
     *     final_price: float
     * }
     */
    public function calculate(ProviderExperience $experience, mixed $basePrice): array
    {
        $originalPrice = round(max(0, (float) $basePrice), 2);

        $percentage = (bool) $experience->allows_discount
            ? (float) ($experience->discount_percentage ?? 0)
            : 0.0;

        $percentage = max(0, min(self::MAX_DISCOUNT_PERCENTAGE, $percentage));
        $discountAmount = round($originalPrice * ($percentage / 100), 2);
        $finalPrice = round(max(0, $originalPrice - $discountAmount), 2);
        $hasDiscount = $percentage >= self::MIN_DISCOUNT_PERCENTAGE
            && $discountAmount > 0;

        return [
            'has_discount' => $hasDiscount,
            'original_price' => $originalPrice,
            'discount_percentage' => $hasDiscount ? $percentage : 0.0,
            'discount_amount' => $hasDiscount ? $discountAmount : 0.0,
            'final_price' => $hasDiscount ? $finalPrice : $originalPrice,
        ];
    }
}
