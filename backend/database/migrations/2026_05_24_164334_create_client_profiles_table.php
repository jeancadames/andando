<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Crea la tabla de perfiles de clientes.
 *
 * Esta tabla guarda la información específica del cliente.
 *
 * Importante:
 * - La tabla users se queda para autenticación e información común.
 * - Esta tabla se relaciona 1 a 1 con users mediante user_id.
 */
return new class extends Migration
{
    /**
     * Ejecuta la migración.
     */
    public function up(): void
    {
        Schema::create('client_profiles', function (Blueprint $table) {
            $table->id();

            /**
             * Relación con users.
             *
             * unique() asegura que un usuario solo pueda tener
             * un perfil de cliente.
             *
             * cascadeOnDelete() elimina el perfil del cliente
             * si se elimina el usuario.
             */
            $table->foreignId('user_id')
                ->unique()
                ->constrained('users')
                ->cascadeOnDelete();

            /**
             * Foto de perfil del cliente.
             *
             * Aquí puedes guardar una ruta tipo:
             * avatars/clientes/foto.jpg
             */
            $table->string('avatar_path')->nullable();

            /**
             * Datos demográficos del cliente.
             */
            $table->date('birth_date')->nullable();
            $table->string('gender')->nullable();
            $table->string('nationality')->nullable();
            $table->string('residence_city')->nullable();

            /**
             * Preferencias del cliente.
             */
            $table->string('preferred_currency')->default('DOP');
            $table->string('language')->default('es');

            /**
             * País o ubicación principal.
             */
            $table->string('country')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Revierte la migración.
     */
    public function down(): void
    {
        Schema::dropIfExists('client_profiles');
    }
};