<?php

namespace App\Http\Controllers\Api\Payments;

use App\Http\Controllers\Controller;
use App\Models\CustomerPaymentMethod;
use App\Models\PaymentMethodTokenizationRequest;
use App\Services\Payments\AzulPaymentPageTokenizationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AzulPaymentPageController extends Controller
{
    public function createTokenizationSession(
        Request $request,
        AzulPaymentPageTokenizationService $service,
    ): JsonResponse {
        $session = $service->createSession($request->user());

        return response()->json([
            'message' => 'Sesión de tokenización creada correctamente.',
            'data' => [
                'redirect_url' => route(
                    'payments.azul.payment-page.redirect',
                    ['tokenizationRequest' => $session['session']->id]
                ),
                'order_number' => $session['order_number'],
            ],
        ]);
    }

    public function redirectTokenization(
        PaymentMethodTokenizationRequest $tokenizationRequest
    ) {
        abort_if(
            $tokenizationRequest->status !== PaymentMethodTokenizationRequest::STATUS_PENDING,
            403,
            'Esta sesión de tokenización ya no está disponible.'
        );

        return view('payments.azul.payment-page-post', [
            'paymentPageUrl' => config('payments.azul.payment_page.url'),
            'fields' => $tokenizationRequest->request_payload,
        ]);
    }

    public function approved(Request $request): RedirectResponse
    {
        return $this->handleCallback(
            $request,
            PaymentMethodTokenizationRequest::STATUS_APPROVED
        );
    }

    public function declined(Request $request): RedirectResponse
    {
        return $this->handleCallback(
            $request,
            PaymentMethodTokenizationRequest::STATUS_DECLINED
        );
    }

    public function cancelled(Request $request): RedirectResponse
    {
        return $this->handleCallback(
            $request,
            PaymentMethodTokenizationRequest::STATUS_CANCELLED
        );
    }

    private function handleCallback(Request $request, string $status): RedirectResponse
    {
        $payload = $request->all();
        $orderNumber = $payload['OrderNumber'] ?? null;

        if (! $this->isValidResponseAuthHash($payload)) {
            return redirect($this->returnUrl('failed'));
        }

        $session = PaymentMethodTokenizationRequest::where('order_number', $orderNumber)->first();

        if (! $session) {
            return redirect($this->returnUrl('failed'));
        }

        DB::transaction(function () use ($session, $payload, $status) {
            $session->update([
                'status' => $status,
                'azul_order_id' => $payload['AzulOrderId'] ?? null,
                'authorization_code' => $payload['AuthorizationCode'] ?? null,
                'rrn' => $payload['RRN'] ?? null,
                'datavault_token' => $payload['DataVaultToken'] ?? null,
                'datavault_brand' => $payload['DataVaultBrand'] ?? null,
                'datavault_expiration' => $payload['DataVaultExpiration'] ?? null,
                'masked_card_number' => $payload['CardNumber'] ?? null,
                'response_code' => $payload['ResponseCode'] ?? null,
                'iso_code' => $payload['IsoCode'] ?? null,
                'response_message' => $payload['ResponseMessage'] ?? null,
                'error_description' => $payload['ErrorDescription'] ?? null,
                'response_payload' => $payload,
                'approved_at' => $status === PaymentMethodTokenizationRequest::STATUS_APPROVED ? now() : null,
                'declined_at' => $status === PaymentMethodTokenizationRequest::STATUS_DECLINED ? now() : null,
                'cancelled_at' => $status === PaymentMethodTokenizationRequest::STATUS_CANCELLED ? now() : null,
            ]);

            if ($status !== PaymentMethodTokenizationRequest::STATUS_APPROVED) {
                return;
            }

            if (blank($session->datavault_token)) {
                $session->update([
                    'status' => PaymentMethodTokenizationRequest::STATUS_FAILED,
                    'error_description' => 'Azul no devolvió DataVaultToken.',
                ]);

                return;
            }

            $hasDefault = CustomerPaymentMethod::where('user_id', $session->user_id)
                ->where('is_default', true)
                ->exists();

            $expiration = $this->parseExpiration($session->datavault_expiration);

            $method = CustomerPaymentMethod::create([
                'user_id' => $session->user_id,
                'gateway' => 'azul',
                'type' => 'credit',
                'brand' => $session->datavault_brand ?? 'unknown',
                'last4' => $this->extractLast4($session->masked_card_number),
                'masked_card_number' => $session->masked_card_number,
                'holder_name' => $this->resolveHolderName($session),
                'expiry_month' => $expiration['month'],
                'expiry_year' => $expiration['year'],
                'is_default' => ! $hasDefault,
                'payment_token' => $session->datavault_token,
                'token_expires_at' => null,
                'gateway_response_payload' => $payload,
            ]);

            $session->update([
                'customer_payment_method_id' => $method->id,
            ]);
        });

        return redirect($this->returnUrl($status));
    }

    private function returnUrl(string $status): string
    {
        $baseUrl = config('payments.azul.payment_page.payment_method_return_url');

        return $baseUrl . '?status=' . $status;
    }

    private function extractLast4(?string $maskedCard): ?string
    {
        if (! $maskedCard) {
            return null;
        }

        $digits = preg_replace('/\D/', '', $maskedCard);

        return $digits ? substr($digits, -4) : null;
    }

    private function parseExpiration(?string $expiration): array
    {
        if (! $expiration) {
            return [
                'month' => null,
                'year' => null,
            ];
        }

        $digits = preg_replace('/\D/', '', $expiration);

        if (strlen($digits) >= 6) {
            return [
                'month' => (int) substr($digits, 4, 2),
                'year' => (int) substr($digits, 0, 4),
            ];
        }

        if (strlen($digits) === 4) {
            return [
                'month' => (int) substr($digits, 0, 2),
                'year' => 2000 + (int) substr($digits, 2, 2),
            ];
        }

        return [
            'month' => null,
            'year' => null,
        ];
    }

    private function isValidResponseAuthHash(array $payload): bool
    {
        $receivedHash = (string) ($payload['AuthHash'] ?? '');

        if (blank($receivedHash)) {
            return false;
        }

        $privateKey = trim((string) config('payments.azul.payment_page.private_key'));

        $plainText =
            (string) ($payload['OrderNumber'] ?? '') .
            (string) ($payload['Amount'] ?? '') .
            (string) ($payload['AuthorizationCode'] ?? '') .
            (string) ($payload['DateTime'] ?? '') .
            (string) ($payload['ResponseCode'] ?? '') .
            (string) ($payload['IsoCode'] ?? $payload['ISOCode'] ?? '') .
            (string) ($payload['ResponseMessage'] ?? '') .
            (string) ($payload['ErrorDescription'] ?? '') .
            (string) ($payload['RRN'] ?? '') .
            $privateKey;

        $plainTextUtf16 = mb_convert_encoding($plainText, 'UTF-16LE', 'UTF-8');

        $generatedHash = hash_hmac('sha512', $plainTextUtf16, $privateKey);

        return hash_equals(
            strtolower($generatedHash),
            strtolower($receivedHash)
        );
    }

    private function resolveHolderName(PaymentMethodTokenizationRequest $session): string
    {
        $user = $session->user;

        $name = trim((string) ($user?->name ?? ''));

        if ($name !== '') {
            return $name;
        }

        $firstName = trim((string) ($user?->first_name ?? ''));
        $lastName = trim((string) ($user?->last_name ?? ''));

        $fullName = trim($firstName . ' ' . $lastName);

        if ($fullName !== '') {
            return $fullName;
        }

        return 'Tarjeta guardada';
    }

}