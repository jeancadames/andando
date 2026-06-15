<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->boolean('includes_transport')
                ->default(false)
                ->after('experience_longitude');
        });
    }

    public function down(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->dropColumn('includes_transport');
        });
    }
};