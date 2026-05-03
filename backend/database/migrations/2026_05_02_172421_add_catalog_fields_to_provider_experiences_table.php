<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Agrega los campos reales que necesita el formulario de creación
 * de experiencias del afiliado.
 *
 * provider_experiences representa el producto base del catálogo.
 * Ejemplo: "Aventura en Samaná".
 *
 * Las fechas específicas se manejarán en provider_experience_schedules.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            if (! Schema::hasColumn('provider_experiences', 'category')) {
                $table->string('category')->nullable()->after('title');
            }

            if (! Schema::hasColumn('provider_experiences', 'duration')) {
                $table->string('duration')->nullable()->after('description');
            }

            if (! Schema::hasColumn('provider_experiences', 'province')) {
                $table->string('province')->nullable()->after('location');
            }

            if (! Schema::hasColumn('provider_experiences', 'start_location')) {
                $table->text('start_location')->nullable()->after('province');
            }

            if (! Schema::hasColumn('provider_experiences', 'pickup_points')) {
                $table->json('pickup_points')->nullable()->after('start_location');
            }

            if (! Schema::hasColumn('provider_experiences', 'currency')) {
                $table->string('currency', 3)->default('DOP')->after('price');
            }

            if (! Schema::hasColumn('provider_experiences', 'itinerary')) {
                $table->json('itinerary')->nullable()->after('capacity');
            }

            if (! Schema::hasColumn('provider_experiences', 'amenities')) {
                $table->json('amenities')->nullable()->after('itinerary');
            }

            if (! Schema::hasColumn('provider_experiences', 'included')) {
                $table->json('included')->nullable()->after('amenities');
            }

            if (! Schema::hasColumn('provider_experiences', 'not_included')) {
                $table->json('not_included')->nullable()->after('included');
            }

            if (! Schema::hasColumn('provider_experiences', 'requirements')) {
                $table->json('requirements')->nullable()->after('not_included');
            }

            if (! Schema::hasColumn('provider_experiences', 'cancellation_policy')) {
                $table->string('cancellation_policy')->nullable()->after('requirements');
            }

            if (! Schema::hasColumn('provider_experiences', 'published_at')) {
                $table->timestamp('published_at')->nullable()->after('status');
            }

            if (! Schema::hasColumn('provider_experiences', 'deleted_at')) {
                $table->softDeletes();
            }
        });
    }

    public function down(): void
    {
        Schema::table('provider_experiences', function (Blueprint $table) {
            $table->dropColumn([
                'category',
                'duration',
                'province',
                'start_location',
                'pickup_points',
                'currency',
                'itinerary',
                'amenities',
                'included',
                'not_included',
                'requirements',
                'cancellation_policy',
                'published_at',
                'deleted_at',
            ]);
        });
    }
};