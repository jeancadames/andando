<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Conversaciones entre clientes y afiliados.
 *
 * Una conversación nace desde una experiencia.
 * No depende de una reserva.
 * Si luego el cliente reserva, se vincula con provider_booking_id.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('conversations')) {
            return;
        }

        Schema::create('conversations', function (Blueprint $table) {
            $table->id();

            /**
             * Cliente autenticado.
             *
             * En tu app el cliente vive en users.
             */
            $table->foreignId('customer_user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            /**
             * Afiliado dueño de la experiencia.
             */
            $table->foreignId('provider_id')
                ->constrained('providers')
                ->cascadeOnDelete();

            /**
             * Experiencia sobre la que se conversa.
             */
            $table->foreignId('provider_experience_id')
                ->constrained('provider_experiences')
                ->cascadeOnDelete();

            /**
             * Reserva vinculada.
             *
             * Puede ser null porque el chat existe antes de reservar.
             */
            $table->foreignId('provider_booking_id')
                ->nullable()
                ->constrained('provider_bookings')
                ->nullOnDelete();

            /**
             * open:
             * - conversación activa.
             *
             * closed:
             * - cerrada automáticamente por inactividad.
             */
            $table->enum('status', [
                'open',
                'closed',
            ])->default('open');

            $table->string('closed_reason')->nullable();
            $table->timestamp('closed_at')->nullable();

            /**
             * Resumen rápido para listas.
             */
            $table->text('last_message')->nullable();
            $table->timestamp('last_message_at')->nullable();

            /**
             * Contadores de no leídos.
             */
            $table->unsignedInteger('customer_unread_count')->default(0);
            $table->unsignedInteger('provider_unread_count')->default(0);

            $table->timestamps();

            /**
             * Regla:
             * una sola conversación por cliente + afiliado + experiencia.
             */
            $table->unique(
                [
                    'customer_user_id',
                    'provider_id',
                    'provider_experience_id',
                ],
                'conv_customer_provider_exp_unique'
            );

            $table->index(['customer_user_id', 'status'], 'conv_customer_status_idx');
            $table->index(['provider_id', 'status'], 'conv_provider_status_idx');
            $table->index('last_message_at', 'conv_last_message_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};