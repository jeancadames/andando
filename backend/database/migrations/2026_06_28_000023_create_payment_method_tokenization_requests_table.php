<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_method_tokenization_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->unsignedBigInteger('customer_payment_method_id')->nullable();

            $table->string('gateway')->default('azul');
            $table->string('environment')->default('test');

            $table->string('order_number')->unique();
            $table->string('status')->default('pending');

            $table->string('azul_order_id')->nullable();
            $table->string('authorization_code')->nullable();
            $table->string('rrn')->nullable();

            $table->string('datavault_token')->nullable();
            $table->string('datavault_brand')->nullable();
            $table->string('datavault_expiration')->nullable();
            $table->string('masked_card_number')->nullable();

            $table->string('response_code')->nullable();
            $table->string('iso_code')->nullable();
            $table->string('response_message')->nullable();
            $table->text('error_description')->nullable();

            $table->json('request_payload')->nullable();
            $table->json('response_payload')->nullable();

            $table->timestamp('approved_at')->nullable();
            $table->timestamp('declined_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();

            $table->timestamps();

            $table->foreign('customer_payment_method_id', 'pmt_token_req_method_fk')
                ->references('id')
                ->on('customer_payment_methods')
                ->nullOnDelete();

            $table->index(['user_id', 'status']);
            $table->index(['order_number', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_method_tokenization_requests');
    }
};