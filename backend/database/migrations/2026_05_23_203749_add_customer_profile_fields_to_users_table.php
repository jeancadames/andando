<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Agrega campos necesarios para el perfil del cliente.
 *
 * Estos campos permiten mostrar y editar la pantalla de perfil/configuración:
 * - Foto de perfil
 * - Fecha de nacimiento
 * - Género
 * - Nacionalidad
 * - Ciudad de residencia
 * - Moneda preferida
 * - Idioma
 * - País/ubicación
 */
return new class extends Migration
{
    /**
     * Ejecuta la migración.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('avatar_path')->nullable()->after('phone');
            $table->date('birth_date')->nullable()->after('avatar_path');
            $table->string('gender')->nullable()->after('birth_date');
            $table->string('nationality')->nullable()->after('gender');
            $table->string('residence_city')->nullable()->after('nationality');
            $table->string('preferred_currency')->default('DOP')->after('residence_city');
            $table->string('language')->default('es')->after('preferred_currency');
            $table->string('country')->nullable()->after('language');
        });
    }

    /**
     * Revierte la migración.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'avatar_path',
                'birth_date',
                'gender',
                'nationality',
                'residence_city',
                'preferred_currency',
                'language',
                'country',
            ]);
        });
    }
};