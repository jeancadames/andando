<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Reservas asociadas a experiencias de afiliados.
     * Esta tabla alimenta reservas activas, próximas reservas,
     * ganancias del mes y análisis.
     */
    public function up(): void
    {
        if (Schema::hasTable('provider_bookings')) {
            return;
        }

        Schema::create('provider_bookings', function (Blueprint $table) {
            $table->id();

            // Afiliado/proveedor dueño de la reserva.
            $table->foreignId('provider_id')
                ->constrained('providers')
                ->cascadeOnDelete();

            // Experiencia reservada.
            $table->foreignId('provider_experience_id')
                ->nullable()
                ->constrained('provider_experiences')
                ->nullOnDelete();

            // Cliente autenticado, si existe.
            $table->foreignId('user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->string('booking_code')->unique();

            // Datos mínimos del cliente por si la reserva se hace como invitado.
            $table->string('customer_name')->nullable();
            $table->string('customer_phone')->nullable();
            $table->string('customer_email')->nullable();

            // Fecha y hora de la experiencia.
            $table->dateTime('booking_date');

            // Cantidad de personas.
            $table->unsignedInteger('guests_count')->default(1);

            // Precio unitario al momento de reservar.
            $table->decimal('unit_price', 12, 2)->default(0);

            // Total pagado por el cliente.
            $table->decimal('total_amount', 12, 2)->default(0);

            // Ganancia neta del afiliado.
            // Esto permite descontar comisiones de AndanDO más adelante.
            $table->decimal('provider_earning', 12, 2)->default(0);

            // pending: pendiente de confirmación/pago
            // confirmed: confirmada
            // completed: realizada
            // cancelled: cancelada
            $table->enum('status', [
                'pending',
                'confirmed',
                'completed',
                'cancelled',
            ])->default('pending');

            $table->timestamps();

            $table->index(['provider_id', 'status']);
            $table->index(['provider_id', 'booking_date']);
            $table->index(['provider_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_bookings');
    }
};