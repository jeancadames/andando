<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/// Documentos subidos por el proveedor.
///
/// No guardamos el archivo en la base de datos.
/// Guardamos la ruta en storage.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('provider_documents', function (Blueprint $table) {
            $table->id();

            $table->foreignId('provider_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('provider_verification_request_id')
                ->constrained()
                ->cascadeOnDelete();

            /// Tipo de documento:
            /// identity_card
            /// rnc_certificate
            /// business_license
            $table->string('type', 50);

            /// Estado individual del documento.
            $table->string('status', 30)->default('pending');

            /// Disco donde se guardó.
            /// Ejemplo: private
            $table->string('disk')->default('private');

            /// Ruta interna del archivo.
            $table->string('path');

            /// Nombre original subido por el usuario.
            $table->string('original_name');

            /// MIME type.
            /// Ejemplo: application/pdf, image/png.
            $table->string('mime_type', 120)->nullable();

            /// Tamaño en bytes.
            $table->unsignedBigInteger('size_bytes')->default(0);

            $table->timestamp('reviewed_at')->nullable();

            $table->timestamps();

            $table->index(['provider_id', 'type']);
            $table->index(['provider_verification_request_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_documents');
    }
};