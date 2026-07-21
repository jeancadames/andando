<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->boolean('allows_minors')
                ->default(false)
                ->after('capacity');
        });
    }

    public function down(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->dropColumn('allows_minors');
        });
    }
};
