<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('provider_experiences', 'experience_place_id')) {
            Schema::table('provider_experiences', function (Blueprint $table) {
                $table->string('experience_place_id')
                    ->nullable()
                    ->after('experience_address');
            });
        }

        if (! Schema::hasColumn('provider_experience_pickup_points', 'place_id')) {
            Schema::table('provider_experience_pickup_points', function (Blueprint $table) {
                $table->string('place_id')
                    ->nullable()
                    ->after('address');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('provider_experience_pickup_points', 'place_id')) {
            Schema::table('provider_experience_pickup_points', function (Blueprint $table) {
                $table->dropColumn('place_id');
            });
        }

        if (Schema::hasColumn('provider_experiences', 'experience_place_id')) {
            Schema::table('provider_experiences', function (Blueprint $table) {
                $table->dropColumn('experience_place_id');
            });
        }
    }
};
