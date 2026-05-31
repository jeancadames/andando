<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('provider_reviews')) {
            return;
        }

        Schema::table('provider_reviews', function (Blueprint $table) {
            if (!Schema::hasColumn('provider_reviews', 'provider_response')) {
                $table->text('provider_response')->nullable()->after('comment');
            }

            if (!Schema::hasColumn('provider_reviews', 'provider_response_at')) {
                $table->timestamp('provider_response_at')->nullable()->after('provider_response');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('provider_reviews')) {
            return;
        }

        Schema::table('provider_reviews', function (Blueprint $table) {
            if (Schema::hasColumn('provider_reviews', 'provider_response_at')) {
                $table->dropColumn('provider_response_at');
            }

            if (Schema::hasColumn('provider_reviews', 'provider_response')) {
                $table->dropColumn('provider_response');
            }
        });
    }
};