<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Agrega el punto de recogida seleccionado por el cliente
     * al momento de realizar una reserva.
     */
    public function up(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_bookings', 'pickup_point')) {
                $table->string('pickup_point')
                    ->nullable()
                    ->after('booking_date');
            }
        });
    }

    /**
     * Revierte los cambios.
     */
    public function down(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            if (Schema::hasColumn('provider_bookings', 'pickup_point')) {
                $table->dropColumn('pickup_point');
            }
        });
    }
};