<?php

namespace App\Http\Controllers\Api\Client;

use App\Notifications\Security\PaymentMethodUpdatedNotification;

use App\Http\Controllers\Controller;
use App\Models\CustomerPaymentMethod;
use App\Services\Payments\AzulPaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Controlador de métodos de pago del cliente.
 *
 * Flujo correcto:
 * - Flutter captura tarjeta temporalmente.
 * - Laravel envía datos a Azul Datavault.
 * - Azul devuelve token.
 * - AndanDO guarda solo token + datos seguros.
 *
 * IMPORTANTE:
 * No se guarda número completo ni CVV.
 */
class ClientPaymentMethodController extends Controller
{
    public function __construct(
        private readonly AzulPaymentService $azulPaymentService
    ) {
    }

    /**
     * Lista métodos de pago del cliente autenticado.
     */
    public function index(Request $request): JsonResponse
    {
        $paymentMethods = CustomerPaymentMethod::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('is_default')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'message' => 'Métodos de pago obtenidos correctamente.',
            'data' => [
                'payment_methods' => $paymentMethods
                    ->map(fn (CustomerPaymentMethod $method) => $this->formatPaymentMethod($method))
                    ->values(),
            ],
        ]);
    }

    /**
     * Tokeniza y guarda una tarjeta.
     *
     * Recibe tarjeta temporalmente, la envía a Azul Datavault
     * y solo guarda datos seguros.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => ['required', Rule::in(['credit', 'debit'])],
            'card_number' => ['required', 'string', 'min:13', 'max:25'],
            'holder_name' => ['required', 'string', 'max:120'],
            'expiry_month' => ['required', 'integer', 'between:1,12'],
            'expiry_year' => ['required', 'integer', 'between:2024,2100'],
            'cvv' => ['required', 'string', 'min:3', 'max:4'],
        ]);

        $user = $request->user();

        $tokenization = $this->azulPaymentService->tokenizeCard([
            'card_number' => $validated['card_number'],
            'holder_name' => $validated['holder_name'],
            'expiry_month' => $validated['expiry_month'],
            'expiry_year' => $validated['expiry_year'],
            'cvv' => $validated['cvv'],
            'type' => $validated['type'],
            'user_id' => $user->id,
        ]);

        if (($tokenization['success'] ?? false) !== true) {
            return response()->json([
                'message' => $tokenization['response_message'] ?? 'No se pudo tokenizar la tarjeta.',
            ], 422);
        }

        $method = DB::transaction(function () use ($user, $validated, $tokenization) {
            $hasDefault = CustomerPaymentMethod::query()
                ->where('user_id', $user->id)
                ->where('is_default', true)
                ->exists();

            return CustomerPaymentMethod::query()->create([
                'user_id' => $user->id,
                'gateway' => 'azul',
                'type' => $validated['type'],
                'brand' => $tokenization['brand'] ?? 'unknown',
                'last4' => $tokenization['last4'],
                'masked_card_number' => $tokenization['masked_card_number'] ?? null,
                'holder_name' => strtoupper($validated['holder_name']),
                'expiry_month' => $validated['expiry_month'],
                'expiry_year' => $validated['expiry_year'],
                'is_default' => ! $hasDefault,
                'payment_token' => $tokenization['token'],
                'token_expires_at' => $tokenization['token_expires_at'] ?? null,
                'gateway_response_payload' => $tokenization['raw_response'] ?? null,
            ]);
        });

        $user->notify(
            new PaymentMethodUpdatedNotification('created', $method)
        );

        return response()->json([
            'message' => 'Tarjeta tokenizada y guardada correctamente.',
            'data' => [
                'payment_method' => $this->formatPaymentMethod($method),
            ],
        ], 201);
    }

    /**
     * Establece una tarjeta como principal.
     */
    public function setDefault(Request $request, CustomerPaymentMethod $paymentMethod): JsonResponse
    {
        $this->ensureOwner($request, $paymentMethod);

        DB::transaction(function () use ($request, $paymentMethod) {
            CustomerPaymentMethod::query()
                ->where('user_id', $request->user()->id)
                ->update([
                    'is_default' => false,
                ]);

            $paymentMethod->update([
                'is_default' => true,
            ]);
        });

        $request->user()->notify(
            new PaymentMethodUpdatedNotification('default_updated', $paymentMethod->fresh())
        );

        return response()->json([
            'message' => 'Tarjeta principal actualizada correctamente.',
            'data' => [
                'payment_method' => $this->formatPaymentMethod($paymentMethod->fresh()),
            ],
        ]);
    }

    /**
     * Elimina una tarjeta.
     *
     * Primero intenta eliminar/desactivar el token en Azul.
     * Luego hace soft delete local.
     */
    public function destroy(Request $request, CustomerPaymentMethod $paymentMethod): JsonResponse
    {
        $this->ensureOwner($request, $paymentMethod);

        $deletedPaymentMethod = $paymentMethod->replicate();

        DB::transaction(function () use ($request, $paymentMethod) {
            $wasDefault = $paymentMethod->is_default;

            if ($paymentMethod->hasGatewayToken()) {
                $this->azulPaymentService->deleteToken($paymentMethod->payment_token);
            }

            $paymentMethod->delete();

            if ($wasDefault) {
                $nextMethod = CustomerPaymentMethod::query()
                    ->where('user_id', $request->user()->id)
                    ->latest()
                    ->first();

                if ($nextMethod) {
                    $nextMethod->update([
                        'is_default' => true,
                    ]);
                }
            }
        });

        $request->user()->notify(
            new PaymentMethodUpdatedNotification('deleted', $deletedPaymentMethod)
        );

        return response()->json([
            'message' => 'Tarjeta eliminada correctamente.',
        ]);
    }

    /**
     * Valida que el método pertenezca al usuario autenticado.
     */
    private function ensureOwner(Request $request, CustomerPaymentMethod $paymentMethod): void
    {
        abort_if(
            $paymentMethod->user_id !== $request->user()->id,
            403,
            'No tienes permiso para modificar esta tarjeta.'
        );
    }

    /**
     * Formatea el método de pago para Flutter.
     */
    private function formatPaymentMethod(CustomerPaymentMethod $method): array
    {
        return [
            'id' => $method->id,
            'gateway' => $method->gateway,
            'type' => $method->type,
            'brand' => $method->brand,
            'last4' => $method->last4,
            'masked_card_number' => $method->masked_card_number,
            'holder_name' => $method->holder_name,
            'expiry_month' => $method->expiry_month,
            'expiry_year' => $method->expiry_year,
            'expiry_label' => str_pad((string) $method->expiry_month, 2, '0', STR_PAD_LEFT)
                . '/'
                . substr((string) $method->expiry_year, -2),
            'is_default' => $method->is_default,
            'has_token' => $method->hasGatewayToken(),
        ];
    }
}