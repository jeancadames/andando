<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('provider_review_photos', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_review_id')
                ->constrained('provider_reviews')
                ->cascadeOnDelete();

            $table->string('photo_path');

            $table->unsignedInteger('sort_order')
                ->default(0);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('provider_review_photos');
    }
};