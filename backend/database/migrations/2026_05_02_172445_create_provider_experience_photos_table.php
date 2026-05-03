<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Fotos asociadas a una experiencia.
 *
 * Se separan en su propia tabla para permitir múltiples imágenes,
 * orden, portada y futuras mejoras como moderación o compresión.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('provider_experience_photos')) {
            return;
        }

        Schema::create('provider_experience_photos', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_experience_id')
                ->constrained('provider_experiences')
                ->cascadeOnDelete();

            $table->string('path');
            $table->string('original_name')->nullable();
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('size_bytes')->nullable();

            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_cover')->default(false);

            $table->timestamps();

            // Nombres cortos para evitar error 1059 de MySQL.
            $table->index(['provider_experience_id', 'is_cover'], 'pexp_photos_cover_idx');
            $table->index(['provider_experience_id', 'sort_order'], 'pexp_photos_sort_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_experience_photos');
    }
};