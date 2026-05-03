<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Reglas/series usadas para crear múltiples fechas programadas.
 *
 * Ejemplo:
 * - Experiencia: Aventura en Samaná
 * - Desde: 2026-05-01
 * - Hasta: 2026-05-31
 * - Frecuencia: custom
 * - Días: monday, wednesday, saturday
 * - Hora: 08:00
 *
 * Las fechas reales siguen viviendo en provider_experience_schedules.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('provider_experience_schedule_series')) {
            return;
        }

        Schema::create('provider_experience_schedule_series', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('provider_id');
            $table->unsignedBigInteger('provider_experience_id');

            $table->date('starts_on');
            $table->date('ends_on');
            $table->time('departure_time');

            $table->string('timezone')->default('America/Santo_Domingo');

            // daily: todos los días
            // weekly: cada 7 días desde starts_on
            // custom: días específicos de la semana
            $table->enum('frequency', [
                'daily',
                'weekly',
                'custom',
            ])->default('daily');

            // Para custom:
            // ["monday", "wednesday", "saturday"]
            $table->json('days_of_week')->nullable();

            $table->enum('status', [
                'active',
                'cancelled',
            ])->default('active');

            $table->timestamps();
            $table->softDeletes();

            $table->foreign('provider_id', 'pexp_series_provider_fk')
                ->references('id')
                ->on('providers')
                ->cascadeOnDelete();

            $table->foreign('provider_experience_id', 'pexp_series_exp_fk')
                ->references('id')
                ->on('provider_experiences')
                ->cascadeOnDelete();

            $table->index(['provider_id', 'status'], 'pexp_series_provider_status_idx');
            $table->index(['provider_experience_id', 'starts_on'], 'pexp_series_exp_start_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_experience_schedule_series');
    }
};