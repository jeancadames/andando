<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->string('experience_address')->nullable()->after('start_location');
            $table->decimal('experience_latitude', 10, 7)->nullable()->after('experience_address');
            $table->decimal('experience_longitude', 10, 7)->nullable()->after('experience_latitude');
        });
    }

    public function down(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->dropColumn([
                'experience_address',
                'experience_latitude',
                'experience_longitude',
            ]);
        });
    }
};