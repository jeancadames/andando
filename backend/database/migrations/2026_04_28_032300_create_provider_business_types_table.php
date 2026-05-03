<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/// Catálogo de tipos de negocio.
///
/// Es mejor tenerlo en tabla y no quemado en Flutter,
/// porque después podrás agregar más tipos desde el backend
/// sin publicar una nueva versión de la app.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_business_types', function (Blueprint $table) {
            $table->id();

            /// Slug interno.
            /// Ejemplo: tourism_agency
            $table->string('slug')->unique();

            /// Nombre visible.
            /// Ejemplo: Agencia de Turismo
            $table->string('name');

            /// Permite desactivar tipos sin borrarlos.
            $table->boolean('is_active')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_business_types');
    }
};