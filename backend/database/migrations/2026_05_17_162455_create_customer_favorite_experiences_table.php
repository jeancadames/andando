<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_favorite_experiences', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->foreignId('provider_experience_id')
                ->constrained('provider_experiences')
                ->cascadeOnDelete();

            $table->timestamps();

            $table->unique(['user_id', 'provider_experience_id'], 'customer_favorite_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_favorite_experiences');
    }
};