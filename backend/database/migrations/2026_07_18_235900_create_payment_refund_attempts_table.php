<?php

// AndanDO Admin Payments Module

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_refund_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_refund_id')
                ->constrained('payment_refunds')
                ->cascadeOnDelete();
            $table->unsignedInteger('attempt_number');
            $table->string('trigger')->default('automatic');
            $table->foreignId('initiated_by_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();
            $table->string('status')->default('processing');
            $table->string('gateway_refund_id')->nullable();
            $table->string('gateway_response_code')->nullable();
            $table->string('gateway_iso_code')->nullable();
            $table->string('gateway_response_message')->nullable();
            $table->text('gateway_error_description')->nullable();
            $table->json('raw_request')->nullable();
            $table->json('raw_response')->nullable();
            $table->timestamp('started_at');
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->unique(['payment_refund_id', 'attempt_number']);
            $table->index(['status', 'created_at']);
            $table->index(['initiated_by_user_id', 'created_at']);
        });

        Schema::table('payment_transactions', function (Blueprint $table) {
            $table->index(['status', 'created_at'], 'admin_payments_status_created_idx');
            $table->index(['gateway', 'created_at'], 'admin_payments_gateway_created_idx');
        });

        Schema::table('payment_refunds', function (Blueprint $table) {
            $table->index(['status', 'created_at'], 'admin_refunds_status_created_idx');
            $table->index(['gateway', 'created_at'], 'admin_refunds_gateway_created_idx');
        });
    }

    public function down(): void
    {
        Schema::table('payment_refunds', function (Blueprint $table) {
            $table->dropIndex('admin_refunds_status_created_idx');
            $table->dropIndex('admin_refunds_gateway_created_idx');
        });

        Schema::table('payment_transactions', function (Blueprint $table) {
            $table->dropIndex('admin_payments_status_created_idx');
            $table->dropIndex('admin_payments_gateway_created_idx');
        });

        Schema::dropIfExists('payment_refund_attempts');
    }
};
