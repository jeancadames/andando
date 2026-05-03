<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Relaciona una fecha programada con la serie que la creó.
 *
 * Una fecha puede ser:
 * - creada manualmente, series_id = null
 * - creada por una programación múltiple, series_id != null
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experience_schedules', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_experience_schedules', 'series_id')) {
                $table->unsignedBigInteger('series_id')
                    ->nullable()
                    ->after('provider_experience_id');

                $table->foreign('series_id', 'pexp_sched_series_fk')
                    ->references('id')
                    ->on('provider_experience_schedule_series')
                    ->nullOnDelete();

                $table->index('series_id', 'pexp_sched_series_idx');
            }
        });
    }

    public function down(): void
    {
        Schema::table('provider_experience_schedules', function (Blueprint $table) {
            if (Schema::hasColumn('provider_experience_schedules', 'series_id')) {
                $table->dropForeign('pexp_sched_series_fk');
                $table->dropIndex('pexp_sched_series_idx');
                $table->dropColumn('series_id');
            }
        });
    }
};