<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Crea la tabla de comentarios sobre reseñas.
     *
     * Cada comentario pertenece a una reseña existente y a un usuario.
     */
    public function up(): void
    {
        Schema::create('provider_review_comments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_review_id')
                ->constrained('provider_reviews')
                ->cascadeOnDelete();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->text('comment');

            $table->boolean('is_visible')
                ->default(true);

            $table->timestamps();
        });
    }

    /**
     * Elimina la tabla de comentarios sobre reseñas.
     */
    public function down(): void
    {
        Schema::dropIfExists('provider_review_comments');
    }
};