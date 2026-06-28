<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_refunds', function (Blueprint $table) {
            $table->id();

            $table->foreignId('payment_transaction_id')->constrained('payment_transactions')->cascadeOnDelete();
            $table->foreignId('provider_booking_id')->constrained('provider_bookings')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();

            $table->string('gateway')->default('fake_azul');
            $table->string('environment')->default('test');

            $table->string('status')->default('pending');
            $table->string('reason')->nullable();

            $table->decimal('amount', 12, 2);
            $table->string('currency', 3)->default('DOP');

            $table->decimal('refund_percent', 5, 2)->nullable();
            $table->decimal('retained_amount', 12, 2)->default(0);

            $table->string('gateway_refund_id')->nullable();
            $table->string('gateway_response_code')->nullable();
            $table->string('gateway_iso_code')->nullable();
            $table->string('gateway_response_message')->nullable();
            $table->text('gateway_error_description')->nullable();

            $table->json('raw_request')->nullable();
            $table->json('raw_response')->nullable();

            $table->timestamp('processed_at')->nullable();

            $table->timestamps();

            $table->index(['payment_transaction_id', 'status']);
            $table->index(['provider_booking_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_refunds');
    }
};