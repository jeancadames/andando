<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Reviews dejadas por clientes.
     * Esta tabla alimenta el rating promedio y la satisfacción.
     */
    public function up(): void
    {
        if (Schema::hasTable('provider_reviews')) {
            return;
        }

        Schema::create('provider_reviews', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_id')
                ->constrained('providers')
                ->cascadeOnDelete();

            $table->foreignId('provider_booking_id')
                ->nullable()
                ->constrained('provider_bookings')
                ->nullOnDelete();

            $table->foreignId('user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            // Rating de 1 a 5.
            $table->unsignedTinyInteger('rating');

            $table->text('comment')->nullable();

            // Permite ocultar reviews reportadas sin borrarlas.
            $table->boolean('is_visible')->default(true);

            $table->timestamps();

            $table->index(['provider_id', 'is_visible']);
            $table->index(['provider_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_reviews');
    }
};