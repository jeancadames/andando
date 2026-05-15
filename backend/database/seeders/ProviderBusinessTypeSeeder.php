<?php

namespace Database\Seeders;

use App\Models\ProviderBusinessType;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seeder de tipos de negocio para afiliados/proveedores.
 *
 * Este catálogo es usado durante el registro de afiliados.
 *
 * Flutter envía el campo:
 *
 * business_type_slug
 *
 * y Laravel valida que ese slug exista en la tabla:
 *
 * provider_business_types
 *
 * Por eso los valores de este seeder deben coincidir exactamente con
 * las opciones que aparecen en el formulario Flutter.
 */
class ProviderBusinessTypeSeeder extends Seeder
{
    /**
     * Ejecuta el seeder.
     *
     * Este método crea o actualiza los tipos de negocio permitidos.
     *
     * También corrige el registro viejo:
     *
     * agencia-de-tours
     *
     * para convertirlo al slug oficial:
     *
     * tourism_agency
     */
    public function run(): void
    {
        DB::transaction(function (): void {
            /**
             * Desactivamos protección de mass assignment solo dentro
             * de este bloque del seeder.
             *
             * Esto evita errores si el modelo ProviderBusinessType
             * no tiene todos los campos en $fillable.
             */
            ProviderBusinessType::unguarded(function (): void {
                /**
                 * Si existe el slug viejo, lo convertimos al slug oficial.
                 *
                 * Esto mantiene el mismo ID si ya existe un registro en DB,
                 * evitando crear duplicados innecesarios.
                 */
                $legacyBusinessType = ProviderBusinessType::query()
                    ->where('slug', 'agencia-de-tours')
                    ->first();

                $officialTourismAgencyExists = ProviderBusinessType::query()
                    ->where('slug', 'tourism_agency')
                    ->exists();

                if ($legacyBusinessType && ! $officialTourismAgencyExists) {
                    $legacyBusinessType->update([
                        'slug' => 'tourism_agency',
                        'name' => 'Agencia de Turismo',
                        'is_active' => true,
                    ]);
                }

                /**
                 * Catálogo oficial que Flutter puede enviar.
                 *
                 * Estos valores deben coincidir con:
                 *
                 * lib/features/provider/onboarding/presentation/widgets/step_business_info.dart
                 */
                $businessTypes = [
                    [
                        'slug' => 'tourism_agency',
                        'name' => 'Agencia de Turismo',
                    ],
                    [
                        'slug' => 'tour_operator',
                        'name' => 'Tour Operador',
                    ],
                    [
                        'slug' => 'tour_guide',
                        'name' => 'Guía Turístico',
                    ],
                    [
                        'slug' => 'tourism_transport',
                        'name' => 'Transporte Turístico',
                    ],
                    [
                        'slug' => 'activities_experiences',
                        'name' => 'Actividades y Experiencias',
                    ],
                    [
                        'slug' => 'other',
                        'name' => 'Otro',
                    ],
                ];

                foreach ($businessTypes as $businessType) {
                    ProviderBusinessType::query()->updateOrCreate(
                        [
                            'slug' => $businessType['slug'],
                        ],
                        [
                            'name' => $businessType['name'],
                            'is_active' => true,
                        ],
                    );
                }
            });
        });
    }
}