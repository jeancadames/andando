<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Prepara customer_payment_methods para Azul Datavault.
 *
 * AndanDO NO guarda número completo ni CVV.
 * Solo guarda token, marca, last4 y datos visuales.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customer_payment_methods', function (Blueprint $table) {
            if (! Schema::hasColumn('customer_payment_methods', 'gateway')) {
                $table->string('gateway')->default('azul')->after('user_id');
            }

            if (! Schema::hasColumn('customer_payment_methods', 'masked_card_number')) {
                $table->string('masked_card_number')->nullable()->after('last4');
            }

            if (! Schema::hasColumn('customer_payment_methods', 'token_expires_at')) {
                $table->timestamp('token_expires_at')->nullable()->after('payment_token');
            }

            if (! Schema::hasColumn('customer_payment_methods', 'gateway_response_payload')) {
                $table->json('gateway_response_payload')->nullable()->after('token_expires_at');
            }

            if (! Schema::hasColumn('customer_payment_methods', 'deleted_at')) {
                $table->softDeletes();
            }
        });
    }

    public function down(): void
    {
        Schema::table('customer_payment_methods', function (Blueprint $table) {
            if (Schema::hasColumn('customer_payment_methods', 'gateway')) {
                $table->dropColumn('gateway');
            }

            if (Schema::hasColumn('customer_payment_methods', 'masked_card_number')) {
                $table->dropColumn('masked_card_number');
            }

            if (Schema::hasColumn('customer_payment_methods', 'token_expires_at')) {
                $table->dropColumn('token_expires_at');
            }

            if (Schema::hasColumn('customer_payment_methods', 'gateway_response_payload')) {
                $table->dropColumn('gateway_response_payload');
            }

            if (Schema::hasColumn('customer_payment_methods', 'deleted_at')) {
                $table->dropSoftDeletes();
            }
        });
    }
};