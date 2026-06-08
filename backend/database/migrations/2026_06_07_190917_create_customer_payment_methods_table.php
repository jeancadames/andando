<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Crea la tabla de métodos de pago del cliente.
 *
 * IMPORTANTE:
 * Esta tabla NO guarda número completo de tarjeta ni CVV.
 *
 * Para cumplir buenas prácticas de seguridad, solo guardamos:
 * - marca de tarjeta
 * - últimos 4 dígitos
 * - titular
 * - vencimiento
 * - token futuro del procesador de pago
 */
return new class extends Migration
{
    /**
     * Ejecuta la migración.
     */
    public function up(): void
    {
        Schema::create('customer_payment_methods', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('type')->default('credit'); // credit, debit
            $table->string('brand')->default('visa'); // visa, mastercard, amex, discover
            $table->string('last4', 4);
            $table->string('holder_name');
            $table->unsignedTinyInteger('expiry_month');
            $table->unsignedSmallInteger('expiry_year');

            $table->boolean('is_default')->default(false);

            // Futuro token de Stripe/Azul/PayPal. Nunca guardar PAN/CVV.
            $table->string('payment_token')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'is_default']);
        });
    }

    /**
     * Revierte la migración.
     */
    public function down(): void
    {
        Schema::dropIfExists('customer_payment_methods');
    }
};