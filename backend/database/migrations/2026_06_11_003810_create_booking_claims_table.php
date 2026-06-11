<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_claims', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_booking_id')
                ->constrained('provider_bookings')
                ->cascadeOnDelete();

            $table->foreignId('provider_id')
                ->constrained('providers')
                ->cascadeOnDelete();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('reason');
            $table->text('description');

            $table->enum('status', [
                'pending',
                'provider_replied',
                'resolved',
                'rejected',
            ])->default('pending');

            $table->text('provider_response')->nullable();

            $table->timestamp('provider_replied_at')->nullable();

            $table->timestamp('resolved_at')->nullable();

            $table->timestamps();

            // Una reclamación por reserva
            $table->unique('provider_booking_id');

            $table->index(['provider_id', 'status']);
            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_claims');
    }
};