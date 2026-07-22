<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            $table->boolean('includes_minors')
                ->default(false)
                ->after('guests_count');

            $table->unsignedInteger('minor_count')
                ->default(0)
                ->after('includes_minors');
        });
    }

    public function down(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            $table->dropColumn([
                'includes_minors',
                'minor_count',
            ]);
        });
    }
};