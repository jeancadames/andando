<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mensajes de conversaciones.
 *
 * No se eliminan mensajes.
 * Puede ser:
 * - solo texto
 * - solo imagen
 * - texto + imagen
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('conversation_messages')) {
            return;
        }

        Schema::create('conversation_messages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('conversation_id')
                ->constrained('conversations')
                ->cascadeOnDelete();

            /**
             * Usuario que envió el mensaje.
             *
             * Tanto cliente como afiliado viven en users.
             */
            $table->foreignId('sender_user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            /**
             * Tipo del remitente.
             */
            $table->enum('sender_type', [
                'customer',
                'provider',
            ]);

            /**
             * Texto del mensaje.
             *
             * Nullable porque puede ser solo imagen.
             */
            $table->text('message')->nullable();

            /**
             * Imagen adjunta.
             */
            $table->string('attachment_path')->nullable();
            $table->string('attachment_type')->nullable();
            $table->string('attachment_original_name')->nullable();
            $table->string('attachment_mime_type')->nullable();
            $table->unsignedBigInteger('attachment_size_bytes')->nullable();

            /**
             * Leído por el receptor.
             */
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            $table->index(['conversation_id', 'created_at'], 'conv_msg_conversation_created_idx');
            $table->index(['sender_user_id', 'sender_type'], 'conv_msg_sender_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversation_messages');
    }
};