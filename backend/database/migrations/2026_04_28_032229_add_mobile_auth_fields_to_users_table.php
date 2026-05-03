<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/// Esta migración agrega campos mínimos al usuario para poder
/// distinguir si es cliente, proveedor o administrador.
///
/// En Flutter usaremos este campo para saber a qué flujo mandar al usuario.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            /// Tipo de usuario dentro de la app móvil.
            /// customer = cliente
            /// provider = proveedor
            /// admin = administrador interno
            $table->string('type', 30)
                ->default('customer')
                ->after('email');

            /// Teléfono del usuario.
            $table->string('phone', 30)
                ->nullable()
                ->after('type');

            $table->index('type');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['type']);
            $table->dropColumn(['type', 'phone']);
        });
    }
};