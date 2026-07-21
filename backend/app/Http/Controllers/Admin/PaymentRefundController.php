<?php

namespace App\Http\Controllers\Admin;

// AndanDO Admin Payments Module

use App\Http\Controllers\Controller;
use App\Models\PaymentRefund;
use App\Services\Payments\RetryFailedPaymentRefundService;
use DomainException;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class PaymentRefundController extends Controller
{
    public function index(
        Request $request,
        RetryFailedPaymentRefundService $retryService
    ): Response {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', Rule::in([
                'all', 'pending', 'processing', 'pending_verification', 'succeeded', 'failed',
            ])],
            'gateway' => ['nullable', 'string', 'max:50'],
            'from' => ['nullable', 'date_format:Y-m-d'],
            'to' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from'],
        ]);

        $filters = [
            'search' => trim((string) ($validated['search'] ?? '')),
            'status' => (string) ($validated['status'] ?? 'all'),
            'gateway' => trim((string) ($validated['gateway'] ?? '')),
            'from' => (string) ($validated['from'] ?? ''),
            'to' => (string) ($validated['to'] ?? ''),
        ];

        $query = PaymentRefund::query()->with([
            'transaction:id,status,amount,currency,gateway_order_id',
            'transaction.refunds:id,payment_transaction_id,status',
            'booking:id,booking_code,provider_id,provider_experience_id,customer_name,booking_date',
            'booking.experience:id,title',
            'booking.provider:id,business_name',
            'user:id,name,email',
        ]);

        if ($filters['search'] !== '') {
            $search = $filters['search'];
            $query->where(function (Builder $builder) use ($search) {
                if (ctype_digit($search)) {
                    $builder->orWhereKey((int) $search);
                }

                $builder
                    ->orWhere('gateway_refund_id', 'like', "%{$search}%")
                    ->orWhereHas('transaction', fn (Builder $transaction) => $transaction
                        ->where('gateway_order_id', 'like', "%{$search}%"))
                    ->orWhereHas('booking', fn (Builder $booking) => $booking
                        ->where('booking_code', 'like', "%{$search}%")
                        ->orWhere('customer_name', 'like', "%{$search}%"))
                    ->orWhereHas('user', fn (Builder $user) => $user
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%"));
            });
        }

        if ($filters['status'] !== 'all') {
            $query->where('status', $filters['status']);
        }

        if ($filters['gateway'] !== '') {
            $query->where('gateway', $filters['gateway']);
        }

        if ($filters['from'] !== '') {
            $query->whereDate('created_at', '>=', $filters['from']);
        }

        if ($filters['to'] !== '') {
            $query->whereDate('created_at', '<=', $filters['to']);
        }

        $refunds = $query
            ->latest('id')
            ->paginate(20)
            ->withQueryString();

        $refunds->getCollection()->each(function (PaymentRefund $refund) use ($retryService) {
            $refund->setAttribute('can_retry', $retryService->canRetry($refund));
        });

        return Inertia::render('Refunds/Index', [
            'refunds' => $refunds,
            'filters' => $filters,
            'gateways' => PaymentRefund::query()
                ->whereNotNull('gateway')
                ->distinct()
                ->orderBy('gateway')
                ->pluck('gateway'),
            'counts' => [
                'all' => PaymentRefund::count(),
                'failed' => PaymentRefund::where('status', PaymentRefund::STATUS_FAILED)->count(),
                'pending_verification' => PaymentRefund::where(
                    'status',
                    PaymentRefund::STATUS_PENDING_VERIFICATION
                )->count(),
                'succeeded' => PaymentRefund::where('status', PaymentRefund::STATUS_SUCCEEDED)->count(),
            ],
        ]);
    }

    public function show(
        PaymentRefund $paymentRefund,
        RetryFailedPaymentRefundService $retryService
    ): Response {
        $paymentRefund->load([
            'transaction',
            'transaction.refunds:id,payment_transaction_id,status',
            'booking.experience:id,title,location,province',
            'booking.provider:id,user_id,business_name,city,province',
            'booking.provider.user:id,name,email,phone',
            'user:id,name,email,phone',
            'attempts' => fn ($query) => $query->orderBy('attempt_number'),
            'attempts.initiatedBy:id,name,email',
        ]);

        $paymentRefund->setAttribute('can_retry', $retryService->canRetry($paymentRefund));

        return Inertia::render('Refunds/Show', [
            'refund' => $paymentRefund,
        ]);
    }

    public function retry(
        Request $request,
        PaymentRefund $paymentRefund,
        RetryFailedPaymentRefundService $retryService
    ): RedirectResponse {
        try {
            $result = $retryService->retry($paymentRefund, (int) $request->user()->id);
        } catch (DomainException $exception) {
            return back()->with('error', $exception->getMessage());
        }

        return back()->with(
            $result->status === PaymentRefund::STATUS_SUCCEEDED ? 'success' : 'error',
            match ($result->status) {
                PaymentRefund::STATUS_SUCCEEDED => 'La devolución se procesó correctamente.',
                PaymentRefund::STATUS_PENDING_VERIFICATION => 'Azul no confirmó el resultado. No vuelvas a intentarlo hasta verificarlo con la pasarela.',
                default => 'La devolución volvió a fallar. Se guardó el intento completo.',
            }
        );
    }
}
