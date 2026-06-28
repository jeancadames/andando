<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('provider_bookings', 'customer_payment_method_id')) {
                $table->foreignId('customer_payment_method_id')
                    ->nullable()
                    ->after('user_id')
                    ->constrained('customer_payment_methods')
                    ->nullOnDelete();
            }

            if (!Schema::hasColumn('provider_bookings', 'payment_status')) {
                $table->string('payment_status')->nullable()->after('status');
            }

            if (!Schema::hasColumn('provider_bookings', 'refund_status')) {
                $table->string('refund_status')->nullable()->after('payment_status');
            }

            if (!Schema::hasColumn('provider_bookings', 'provider_payout_status')) {
                $table->string('provider_payout_status')->nullable()->after('refund_status');
            }

            if (!Schema::hasColumn('provider_bookings', 'charge_scheduled_at')) {
                $table->timestamp('charge_scheduled_at')->nullable()->after('provider_payout_status');
            }

            if (!Schema::hasColumn('provider_bookings', 'charged_at')) {
                $table->timestamp('charged_at')->nullable()->after('charge_scheduled_at');
            }

            if (!Schema::hasColumn('provider_bookings', 'refunded_at')) {
                $table->timestamp('refunded_at')->nullable()->after('charged_at');
            }

            if (!Schema::hasColumn('provider_bookings', 'cancelled_by')) {
                $table->string('cancelled_by')->nullable()->after('refunded_at');
            }

            if (!Schema::hasColumn('provider_bookings', 'cancellation_reason')) {
                $table->text('cancellation_reason')->nullable()->after('cancelled_by');
            }
        });
    }

    public function down(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            $columns = [
                'customer_payment_method_id',
                'payment_status',
                'refund_status',
                'provider_payout_status',
                'charge_scheduled_at',
                'charged_at',
                'refunded_at',
                'cancelled_by',
                'cancellation_reason',
            ];

            foreach ($columns as $column) {
                if (Schema::hasColumn('provider_bookings', $column)) {
                    if ($column === 'customer_payment_method_id') {
                        try {
                            $table->dropConstrainedForeignId($column);
                        } catch (\Throwable $e) {
                            $table->dropColumn($column);
                        }
                    } else {
                        $table->dropColumn($column);
                    }
                }
            }
        });
    }
};