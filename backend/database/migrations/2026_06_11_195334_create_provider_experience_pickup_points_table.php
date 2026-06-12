<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Puntos de recogida geolocalizados para experiencias.
     *
     * Cada experiencia puede tener uno o varios puntos de recogida.
     * Estos puntos se usarán para mostrarlos en Google Maps.
     */
    public function up(): void
    {
        if (Schema::hasTable('provider_experience_pickup_points')) {
            return;
        }

        Schema::create('provider_experience_pickup_points', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_experience_id')
                ->constrained('provider_experiences')
                ->cascadeOnDelete();

            $table->string('name')->nullable();
            // Ejemplo: "Lobby del hotel", "Parque Central", "Entrada principal"

            $table->string('address')->nullable();
            // Dirección legible para el cliente.

            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);

            $table->text('instructions')->nullable();
            // Ejemplo: "Estar 15 minutos antes", "Buscar una van blanca"

            $table->unsignedInteger('sort_order')->default(0);

            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('provider_experience_id', 'pepp_experience_idx');
            $table->index(['provider_experience_id', 'is_active'], 'pepp_exp_active_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_experience_pickup_points');
    }
};