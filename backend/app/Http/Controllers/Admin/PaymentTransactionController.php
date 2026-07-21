<?php

namespace App\Http\Controllers\Admin;

// AndanDO Admin Payments Module

use App\Http\Controllers\Controller;
use App\Models\PaymentRefund;
use App\Models\PaymentTransaction;
use App\Services\Payments\RetryFailedPaymentRefundService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class PaymentTransactionController extends Controller
{
    public function index(Request $request): Response
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', Rule::in([
                'all', 'scheduled', 'processing', 'pending_verification',
                'paid', 'failed', 'cancelled', 'refunded', 'partially_refunded',
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

        $query = PaymentTransaction::query()
            ->with([
                'booking:id,booking_code,provider_experience_id,customer_name,booking_date,status',
                'booking.experience:id,title',
                'user:id,name,email',
                'provider:id,business_name',
            ])
            ->withSum([
                'refunds as refunded_amount' => fn (Builder $query) => $query
                    ->where('status', PaymentRefund::STATUS_SUCCEEDED),
            ], 'amount');

        if ($filters['search'] !== '') {
            $search = $filters['search'];
            $query->where(function (Builder $builder) use ($search) {
                if (ctype_digit($search)) {
                    $builder->orWhereKey((int) $search);
                }

                $builder
                    ->orWhere('gateway_order_id', 'like', "%{$search}%")
                    ->orWhere('gateway_transaction_id', 'like', "%{$search}%")
                    ->orWhere('gateway_rrn', 'like', "%{$search}%")
                    ->orWhere('idempotency_key', 'like', "%{$search}%")
                    ->orWhereHas('booking', fn (Builder $booking) => $booking
                        ->where('booking_code', 'like', "%{$search}%"))
                    ->orWhereHas('user', fn (Builder $user) => $user
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%"))
                    ->orWhereHas('provider', fn (Builder $provider) => $provider
                        ->where('business_name', 'like', "%{$search}%"));
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

        $transactions = $query
            ->latest('id')
            ->paginate(20)
            ->withQueryString();

        $chargedStatuses = [
            PaymentTransaction::STATUS_PAID,
            PaymentTransaction::STATUS_REFUNDED,
            PaymentTransaction::STATUS_PARTIALLY_REFUNDED,
        ];

        return Inertia::render('Payments/Index', [
            'transactions' => $transactions,
            'filters' => $filters,
            'gateways' => PaymentTransaction::query()
                ->whereNotNull('gateway')
                ->distinct()
                ->orderBy('gateway')
                ->pluck('gateway'),
            'summary' => [
                'charged_total' => (float) PaymentTransaction::query()
                    ->whereIn('status', $chargedStatuses)
                    ->sum('amount'),
                'refunded_total' => (float) PaymentRefund::query()
                    ->where('status', PaymentRefund::STATUS_SUCCEEDED)
                    ->sum('amount'),
                'pending_verification' => PaymentTransaction::query()
                    ->where('status', PaymentTransaction::STATUS_PENDING_VERIFICATION)
                    ->count(),
                'failed_refunds' => PaymentRefund::query()
                    ->where('status', PaymentRefund::STATUS_FAILED)
                    ->count(),
            ],
        ]);
    }

    public function show(
        PaymentTransaction $paymentTransaction,
        RetryFailedPaymentRefundService $retryService
    ): Response {
        $paymentTransaction->load([
            'booking.experience:id,title,location,province',
            'booking.schedule:id,starts_at,ends_at',
            'user:id,name,email,phone',
            'provider:id,user_id,business_name,city,province',
            'provider.user:id,name,email,phone',
            'paymentMethod:id,brand,last4,masked_card_number',
            'refunds' => fn ($query) => $query->latest('id'),
            'refunds.user:id,name,email',
            'refunds.attempts' => fn ($query) => $query->orderBy('attempt_number'),
            'refunds.attempts.initiatedBy:id,name,email',
        ]);

        $paymentTransaction->refunds->each(function (PaymentRefund $refund) use ($retryService) {
            $refund->setAttribute('can_retry', $retryService->canRetry($refund));
        });

        return Inertia::render('Payments/Show', [
            'transaction' => $paymentTransaction,
            'refundedTotal' => (float) $paymentTransaction->refunds
                ->where('status', PaymentRefund::STATUS_SUCCEEDED)
                ->sum('amount'),
        ]);
    }
}
