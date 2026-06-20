<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            $table->timestamp('trip_reminder_sent_at')
                ->nullable()
                ->after('refund_percentage');
        });
    }

    public function down(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            $table->dropColumn('trip_reminder_sent_at');
        });
    }
};
