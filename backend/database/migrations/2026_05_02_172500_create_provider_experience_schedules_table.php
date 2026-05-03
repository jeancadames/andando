<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Salidas/fechas programadas de una experiencia.
 *
 * Una experiencia puede tener muchas fechas disponibles.
 * Ejemplo:
 * - Experiencia: "Aventura en Samaná"
 * - Salida: 2026-05-10 08:00, 15 cupos, RD$3,500
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('provider_experience_schedules')) {
            return;
        }

        Schema::create('provider_experience_schedules', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_id')
                ->constrained('providers')
                ->cascadeOnDelete();

            $table->foreignId('provider_experience_id')
                ->constrained('provider_experiences')
                ->cascadeOnDelete();

            $table->dateTime('starts_at');
            $table->dateTime('ends_at')->nullable();

            $table->string('timezone')->default('America/Santo_Domingo');

            $table->unsignedInteger('capacity')->default(1);

            $table->decimal('price', 12, 2)->default(0);
            $table->string('currency', 3)->default('DOP');

            // active: disponible para reservas
            // paused: oculta temporalmente
            // completed: ya realizada
            // cancelled: cancelada
            $table->enum('status', [
                'active',
                'paused',
                'completed',
                'cancelled',
            ])->default('active');

            $table->text('notes')->nullable();
            $table->text('cancellation_reason')->nullable();

            $table->timestamps();
            $table->softDeletes();

            // Nombres cortos para evitar error 1059 de MySQL.
            $table->index(['provider_id', 'status'], 'pexp_sched_provider_status_idx');
            $table->index(['provider_id', 'starts_at'], 'pexp_sched_provider_start_idx');
            $table->index(['provider_experience_id', 'starts_at'], 'pexp_sched_exp_start_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_experience_schedules');
    }
};