<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_reviews', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_reviews', 'provider_experience_id')) {
                $table->foreignId('provider_experience_id')
                    ->nullable()
                    ->after('provider_id')
                    ->constrained('provider_experiences')
                    ->nullOnDelete();
            }

            $table->unique('provider_booking_id', 'provider_reviews_booking_unique');
            $table->index(['provider_experience_id', 'is_visible']);
        });
    }

    public function down(): void
    {
        Schema::table('provider_reviews', function (Blueprint $table) {
            $table->dropUnique('provider_reviews_booking_unique');
            $table->dropIndex(['provider_experience_id', 'is_visible']);
            $table->dropConstrainedForeignId('provider_experience_id');
        });
    }
};