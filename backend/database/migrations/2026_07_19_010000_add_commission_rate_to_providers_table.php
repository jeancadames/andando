<?php

// AndanDO Provider Commissions Module

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('providers', function (Blueprint $table) {
            $table->decimal('commission_rate', 5, 4)
                ->nullable()
                ->after('status');
        });

        $defaultRate = max(
            0,
            min(1, (float) config('payments.rules.andando_commission_rate', 0.15))
        );

        DB::table('providers')
            ->whereNull('commission_rate')
            ->update(['commission_rate' => $defaultRate]);

        Schema::create('provider_commission_changes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('provider_id')
                ->constrained('providers')
                ->cascadeOnDelete();
            $table->foreignId('changed_by_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();
            $table->decimal('old_rate', 5, 4)->nullable();
            $table->decimal('new_rate', 5, 4);
            $table->string('source');
            $table->timestamps();

            $table->index(['provider_id', 'created_at']);
            $table->index(['changed_by_user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_commission_changes');

        Schema::table('providers', function (Blueprint $table) {
            $table->dropColumn('commission_rate');
        });
    }
};
