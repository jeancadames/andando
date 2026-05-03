<?php

namespace Database\Seeders;

use App\Models\ProviderBusinessType;
use Illuminate\Database\Seeder;

/// Seeder inicial para los tipos de negocio del proveedor.
class ProviderBusinessTypeSeeder extends Seeder
{
    public function run(): void
    {
        $types = [
            ['slug' => 'tourism_agency', 'name' => 'Agencia de Turismo'],
            ['slug' => 'tour_operator', 'name' => 'Tour Operador'],
            ['slug' => 'tour_guide', 'name' => 'Guía Turístico'],
            ['slug' => 'tourism_transport', 'name' => 'Transporte Turístico'],
            ['slug' => 'activities_experiences', 'name' => 'Actividades y Experiencias'],
            ['slug' => 'other', 'name' => 'Otro'],
        ];

        foreach ($types as $type) {
            ProviderBusinessType::updateOrCreate(
                ['slug' => $type['slug']],
                [
                    'name' => $type['name'],
                    'is_active' => true,
                ],
            );
        }
    }
}