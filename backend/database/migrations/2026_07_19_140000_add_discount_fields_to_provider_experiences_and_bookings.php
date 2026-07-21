<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_experiences', 'allows_discount')) {
                $table->boolean('allows_discount')
                    ->default(false)
                    ->after('price');
            }

            if (! Schema::hasColumn('provider_experiences', 'discount_percentage')) {
                $table->decimal('discount_percentage', 5, 2)
                    ->nullable()
                    ->after('allows_discount');
            }
        });

        Schema::table('provider_bookings', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_bookings', 'original_unit_price')) {
                $table->decimal('original_unit_price', 12, 2)
                    ->nullable()
                    ->after('unit_price');
            }

            if (! Schema::hasColumn('provider_bookings', 'discount_percentage')) {
                $table->decimal('discount_percentage', 5, 2)
                    ->nullable()
                    ->after('original_unit_price');
            }

            if (! Schema::hasColumn('provider_bookings', 'discount_amount')) {
                $table->decimal('discount_amount', 12, 2)
                    ->default(0)
                    ->after('discount_percentage');
            }
        });

        DB::table('provider_bookings')
            ->whereNull('original_unit_price')
            ->update([
                'original_unit_price' => DB::raw('unit_price'),
            ]);
    }

    public function down(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            $columns = array_values(array_filter([
                Schema::hasColumn('provider_bookings', 'original_unit_price')
                    ? 'original_unit_price'
                    : null,
                Schema::hasColumn('provider_bookings', 'discount_percentage')
                    ? 'discount_percentage'
                    : null,
                Schema::hasColumn('provider_bookings', 'discount_amount')
                    ? 'discount_amount'
                    : null,
            ]));

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });

        Schema::table('provider_experiences', function (Blueprint $table) {
            $columns = array_values(array_filter([
                Schema::hasColumn('provider_experiences', 'allows_discount')
                    ? 'allows_discount'
                    : null,
                Schema::hasColumn('provider_experiences', 'discount_percentage')
                    ? 'discount_percentage'
                    : null,
            ]));

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
