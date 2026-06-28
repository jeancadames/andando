<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_transactions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_booking_id')->constrained('provider_bookings')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('provider_id')->constrained('providers')->cascadeOnDelete();
            $table->foreignId('customer_payment_method_id')->nullable()->constrained('customer_payment_methods')->nullOnDelete();

            $table->string('gateway')->default('fake_azul');
            $table->string('environment')->default('test');

            $table->string('type')->default('charge');
            $table->string('status')->default('scheduled');

            $table->decimal('amount', 12, 2);
            $table->string('currency', 3)->default('DOP');
            $table->decimal('itbis_amount', 12, 2)->default(0);

            $table->decimal('commission_rate', 5, 4)->default(0.1500);
            $table->decimal('andando_commission_amount', 12, 2)->default(0);
            $table->decimal('provider_amount', 12, 2)->default(0);

            $table->timestamp('charge_scheduled_at')->nullable();
            $table->timestamp('processed_at')->nullable();

            $table->string('gateway_transaction_id')->nullable();
            $table->string('gateway_order_id')->nullable();
            $table->string('gateway_authorization_code')->nullable();
            $table->string('gateway_rrn')->nullable();

            $table->string('gateway_response_code')->nullable();
            $table->string('gateway_iso_code')->nullable();
            $table->string('gateway_response_message')->nullable();
            $table->text('gateway_error_description')->nullable();

            $table->json('raw_request')->nullable();
            $table->json('raw_response')->nullable();

            $table->string('idempotency_key')->unique();
            $table->text('failure_reason')->nullable();

            $table->timestamps();

            $table->index(['status', 'charge_scheduled_at']);
            $table->index(['provider_booking_id', 'status']);
            $table->foreignId('provider_experience_schedule_id')
                ->constrained('provider_experience_schedules')
                ->cascadeOnDelete();


        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_transactions');
    }
};