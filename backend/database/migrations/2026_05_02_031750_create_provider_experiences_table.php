<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Tabla de experiencias/tours creados por el afiliado.
     * Esta tabla alimenta métricas como "Experiencias publicadas".
     */
    public function up(): void
    {
        if (Schema::hasTable('provider_experiences')) {
            return;
        }

        Schema::create('provider_experiences', function (Blueprint $table) {
            $table->id();

            // Afiliado/proveedor dueño de la experiencia.
            $table->foreignId('provider_id')
                ->constrained('providers')
                ->cascadeOnDelete();

            $table->string('title');
            $table->text('description')->nullable();
            $table->string('location')->nullable();

            // Precio base de la experiencia.
            $table->decimal('price', 12, 2)->default(0);

            // Capacidad máxima por reserva o salida.
            $table->unsignedInteger('capacity')->default(1);

            // draft: creada pero no publicada
            // published: visible para clientes
            // paused: pausada por el afiliado
            // rejected: rechazada por administración
            $table->enum('status', [
                'draft',
                'published',
                'paused',
                'rejected',
            ])->default('draft');

            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index(['provider_id', 'status']);
            $table->index(['provider_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_experiences');
    }
};