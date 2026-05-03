<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/// Tabla principal del proveedor.
///
/// Un usuario puede tener un perfil de proveedor.
/// Aquí vive la información comercial y el estado actual del proveedor.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('providers', function (Blueprint $table) {
            $table->id();

            /// Usuario dueño de este perfil de proveedor.
            $table->foreignId('user_id')
                ->constrained()
                ->cascadeOnDelete();

            /// Tipo de negocio seleccionado.
            $table->foreignId('provider_business_type_id')
                ->constrained()
                ->restrictOnDelete();

            $table->string('business_name');

            /// RNC del negocio.
            /// Lo dejamos unique para evitar proveedores duplicados con el mismo RNC.
            $table->string('rnc', 30)->unique();

            $table->text('address');
            $table->string('city', 100);
            $table->string('province', 100);

            /// Estado del proveedor.
            ///
            /// pending  = solicitud enviada, esperando revisión
            /// approved = aprobado, puede crear experiencias
            /// rejected = rechazado
            /// suspended = bloqueado temporalmente
            $table->string('status', 30)->default('pending');

            /// Motivo del rechazo si aplica.
            $table->text('rejection_reason')->nullable();

            $table->timestamp('approved_at')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->timestamp('suspended_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('providers');
    }
};