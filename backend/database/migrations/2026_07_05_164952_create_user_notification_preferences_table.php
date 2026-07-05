<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_notification_preferences', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->unique()
                ->constrained()
                ->cascadeOnDelete();

            $table->boolean('push_enabled')->default(true);

            $table->boolean('booking_notifications_enabled')->default(true);
            $table->boolean('message_notifications_enabled')->default(true);
            $table->boolean('payment_notifications_enabled')->default(true);
            $table->boolean('claim_notifications_enabled')->default(true);
            $table->boolean('payout_notifications_enabled')->default(true);
            $table->boolean('reminder_notifications_enabled')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_notification_preferences');
    }
};