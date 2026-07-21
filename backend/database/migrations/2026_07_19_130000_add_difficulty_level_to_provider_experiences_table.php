<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('provider_experiences', 'difficulty_level')) {
            return;
        }

        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->string('difficulty_level', 20)
                ->nullable()
                ->after('allows_minors');
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('provider_experiences', 'difficulty_level')) {
            return;
        }

        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->dropColumn('difficulty_level');
        });
    }
};
