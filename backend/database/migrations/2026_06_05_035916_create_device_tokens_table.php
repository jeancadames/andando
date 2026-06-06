<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tokens de dispositivos para notificaciones push.
 *
 * Se deja listo desde ahora.
 * La integración real con Firebase se puede conectar después.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('device_tokens')) {
            return;
        }

        Schema::create('device_tokens', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Antes estaba como text().
            // MySQL no permite unique sobre text sin longitud.
            $table->string('token', 512);

            $table->string('platform', 30)->nullable();
            $table->string('device_name')->nullable();

            $table->timestamp('last_used_at')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'token'], 'device_tokens_user_token_unique');
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
    }
};