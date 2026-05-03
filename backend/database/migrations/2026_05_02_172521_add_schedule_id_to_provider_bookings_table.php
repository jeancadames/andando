<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Relaciona las reservas futuras con una salida específica.
 *
 * Se mantiene provider_experience_id porque ayuda para métricas y consultas,
 * pero la reserva real debe apuntar a provider_experience_schedule_id.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_bookings', 'provider_experience_schedule_id')) {
                $table->foreignId('provider_experience_schedule_id')
                    ->nullable()
                    ->after('provider_experience_id')
                    ->constrained('provider_experience_schedules')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('provider_bookings', function (Blueprint $table) {
            if (Schema::hasColumn('provider_bookings', 'provider_experience_schedule_id')) {
                $table->dropConstrainedForeignId('provider_experience_schedule_id');
            }
        });
    }
};