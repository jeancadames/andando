<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/// Cada vez que un proveedor solicita validación,
/// se crea una solicitud en esta tabla.
///
/// Esto permite historial:
/// - primera solicitud
/// - solicitud rechazada
/// - nueva solicitud con documentos corregidos
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_verification_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_id')
                ->constrained()
                ->cascadeOnDelete();

            /// Estado de la solicitud.
            ///
            /// pending  = pendiente de revisión
            /// approved = aprobada
            /// rejected = rechazada
            $table->string('status', 30)->default('pending');

            $table->timestamp('submitted_at')->nullable();

            /// Usuario administrador que revisó.
            $table->foreignId('reviewed_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->timestamp('reviewed_at')->nullable();

            $table->text('rejection_reason')->nullable();

            /// Guardamos evidencia legal de aceptación.
            $table->boolean('terms_accepted')->default(false);
            $table->timestamp('terms_accepted_at')->nullable();
            $table->string('terms_version', 30)->nullable();

            $table->boolean('privacy_accepted')->default(false);
            $table->timestamp('privacy_accepted_at')->nullable();
            $table->string('privacy_version', 30)->nullable();

            $table->timestamps();

            $table->index(['provider_id', 'status']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_verification_requests');
    }
};