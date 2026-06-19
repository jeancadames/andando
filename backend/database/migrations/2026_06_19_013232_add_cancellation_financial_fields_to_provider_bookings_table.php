<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_bookings', 'cancelled_at')) {
                $table->timestamp('cancelled_at')->nullable()->after('status');
            }

            if (! Schema::hasColumn('provider_bookings', 'cancellation_policy_type')) {
                $table->string('cancellation_policy_type')->nullable()->after('cancelled_at');
            }

            if (! Schema::hasColumn('provider_bookings', 'refund_amount')) {
                $table->decimal('refund_amount', 12, 2)->default(0)->after('cancellation_policy_type');
            }

            if (! Schema::hasColumn('provider_bookings', 'administrative_fee_amount')) {
                $table->decimal('administrative_fee_amount', 12, 2)->default(0)->after('refund_amount');
            }

            if (! Schema::hasColumn('provider_bookings', 'refund_percentage')) {
                $table->unsignedTinyInteger('refund_percentage')->default(0)->after('administrative_fee_amount');
            }
        });
    }

    public function down(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            $table->dropColumn([
                'cancelled_at',
                'cancellation_policy_type',
                'refund_amount',
                'administrative_fee_amount',
                'refund_percentage',
            ]);
        });
    }
};