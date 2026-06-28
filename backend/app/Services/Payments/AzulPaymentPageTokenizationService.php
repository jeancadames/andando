<?php

namespace App\Services\Payments;

use App\Models\PaymentMethodTokenizationRequest;
use App\Models\User;
use Illuminate\Support\Str;

class AzulPaymentPageTokenizationService
{
    public function createSession(User $user): array
    {
        $orderNumber = 'PMT-' . now()->format('YmdHis') . '-' . Str::upper(Str::random(6));

        $fields = [
            'MerchantId' => config('payments.azul.payment_page.merchant_id'),
            'MerchantName' => config('payments.azul.payment_page.merchant_name'),
            'MerchantType' => config('payments.azul.payment_page.merchant_type'),
            'CurrencyCode' => config('payments.azul.payment_page.currency_code'),
            'OrderNumber' => $orderNumber,
            'Amount' => config('payments.azul.payment_page.tokenization_amount', '100'),
            'ITBIS' => config('payments.azul.payment_page.tokenization_itbis', '000'),
            'ApprovedUrl' => config('payments.azul.payment_page.approved_url'),
            'DeclinedUrl' => config('payments.azul.payment_page.declined_url'),
            'CancelUrl' => config('payments.azul.payment_page.cancel_url'),
            'UseCustomField1' => '1',
            'CustomField1Label' => 'UserId',
            'CustomField1Value' => (string) $user->id,
            'UseCustomField2' => '1',
            'CustomField2Label' => 'Purpose',
            'CustomField2Value' => 'save_payment_method',
            'SaveToDataVault' => (string) config('payments.azul.payment_page.save_to_datavault', 1),
        ];

        $fields['AuthHash'] = $this->generateRequestHash($fields);

        $session = PaymentMethodTokenizationRequest::create([
            'user_id' => $user->id,
            'gateway' => 'azul',
            'environment' => config('payments.azul.payment_page.environment', 'test'),
            'order_number' => $orderNumber,
            'status' => PaymentMethodTokenizationRequest::STATUS_PENDING,
            'request_payload' => $fields,
        ]);

        return [
            'session' => $session,
            'session_id' => $session->id,
            'order_number' => $orderNumber,
            'payment_page_url' => config('payments.azul.payment_page.url'),
            'fields' => $fields,
        ];
    }

    private function generateRequestHash(array $fields): string
    {
        $privateKey = trim((string) config('payments.azul.payment_page.private_key'));

        $plainText =
            (string) $fields['MerchantId'] .
            (string) $fields['MerchantName'] .
            (string) $fields['MerchantType'] .
            (string) $fields['CurrencyCode'] .
            (string) $fields['OrderNumber'] .
            (string) $fields['Amount'] .
            (string) $fields['ITBIS'] .
            (string) $fields['ApprovedUrl'] .
            (string) $fields['DeclinedUrl'] .
            (string) $fields['CancelUrl'] .
            (string) $fields['UseCustomField1'] .
            (string) $fields['CustomField1Label'] .
            (string) $fields['CustomField1Value'] .
            (string) $fields['UseCustomField2'] .
            (string) $fields['CustomField2Label'] .
            (string) $fields['CustomField2Value'] .
            $privateKey;

        return hash_hmac('sha512', $plainText, $privateKey);
    }
}