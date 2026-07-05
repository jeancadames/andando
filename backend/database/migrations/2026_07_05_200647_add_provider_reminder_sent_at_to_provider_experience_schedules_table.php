<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experience_schedules', function (Blueprint $table) {
            $table->timestamp('provider_reminder_sent_at')
                ->nullable()
                ->after('cancellation_reason');
        });
    }

    public function down(): void
    {
        Schema::table('provider_experience_schedules', function (Blueprint $table) {
            $table->dropColumn('provider_reminder_sent_at');
        });
    }
};