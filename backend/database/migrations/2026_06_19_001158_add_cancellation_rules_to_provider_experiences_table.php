<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_experiences', 'cancellation_penalty_hours')) {
                $table->unsignedInteger('cancellation_penalty_hours')
                    ->default(24)
                    ->after('cancellation_policy');
            }

            if (! Schema::hasColumn('provider_experiences', 'cancellation_penalty_percentage')) {
                $table->unsignedTinyInteger('cancellation_penalty_percentage')
                    ->default(100)
                    ->after('cancellation_penalty_hours');
            }

            if (! Schema::hasColumn('provider_experiences', 'cancellation_policy_description')) {
                $table->text('cancellation_policy_description')
                    ->nullable()
                    ->after('cancellation_penalty_percentage');
            }
        });
    }

    public function down(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->dropColumn([
                'cancellation_penalty_hours',
                'cancellation_penalty_percentage',
                'cancellation_policy_description',
            ]);
        });
    }
};