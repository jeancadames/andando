<?php

namespace Database\Seeders;


use Illuminate\Support\Facades\DB;
use App\Models\Provider;
use App\Models\ProviderExperience;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Seeder de experiencias demo para la pantalla Explorar.
 *
 * Este seeder:
 * - crea un usuario proveedor demo
 * - crea un provider asociado
 * - crea experiencias publicadas
 *
 * Las experiencias creadas aquí serán visibles desde:
 * GET /api/client/explore/experiences
 */
class ProviderExperienceSeeder extends Seeder
{
    /**
     * Ejecuta el seeder.
     */
    public function run(): void
    {
        /**
         * Crear o buscar usuario demo.
         */
        $user = User::firstOrCreate(
            [
                'email' => 'proveedor.demo@andando.com',
            ],
            [
                'name' => 'Proveedor Demo AndanDO',
                'password' => Hash::make('password123'),
                'type' => 'provider',
            ]
        );

        $businessTypeId = DB::table('provider_business_types')->value('id');

        if (!$businessTypeId) {
            $businessTypeId = DB::table('provider_business_types')->insertGetId([
                'slug' => 'agencia-de-tours',
                'name' => 'Agencia de tours',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        /**
         * Crear o buscar provider asociado al usuario.
         */
        $provider = Provider::firstOrCreate(
            [
                'user_id' => $user->id,
            ],
            [
                'provider_business_type_id' => $businessTypeId,
                'business_name' => 'AndanDO Tours Demo',
                'rnc' => '000000000',
                'address' => 'Santo Domingo, República Dominicana',
                'city' => 'Santo Domingo',
                'province' => 'Santo Domingo',
                'status' => 'approved',
                'approved_at' => now(),
            ]
        );

        /**
         * Experiencias demo visibles para customers y visitantes.
         */
        $experiences = [
            [
                'title' => 'Aventura en Los Haitises',
                'category' => 'Aventura',
                'description' => 'Explora manglares, cuevas y paisajes naturales en una experiencia guiada por el Parque Nacional Los Haitises.',
                'duration' => '6 horas',
                'location' => 'Parque Nacional Los Haitises',
                'province' => 'Samaná',
                'start_location' => 'Muelle de Samaná',
                'pickup_points' => [
                    'Samaná Centro',
                    'Las Terrenas',
                ],
                'price' => 3500,
                'currency' => 'DOP',
                'capacity' => 12,
                'itinerary' => [
                    'Salida desde el muelle',
                    'Recorrido en bote por manglares',
                    'Visita a cuevas',
                    'Tiempo para fotos',
                    'Retorno al punto inicial',
                ],
                'amenities' => [
                    'Guía local',
                    'Transporte marítimo',
                    'Agua',
                ],
                'included' => [
                    'Entrada al parque',
                    'Guía certificado',
                    'Chaleco salvavidas',
                ],
                'not_included' => [
                    'Almuerzo',
                    'Propinas',
                ],
                'requirements' => [
                    'Ropa cómoda',
                    'Protector solar',
                    'Calzado antideslizante',
                ],
                'cancellation_policy' => 'Cancelación gratuita hasta 24 horas antes.',
                'status' => 'published',
                'published_at' => now(),
                'is_active' => true,
            ],

            [
                'title' => 'Ruta cultural por la Zona Colonial',
                'category' => 'Cultural',
                'description' => 'Camina por las calles históricas de Santo Domingo y descubre monumentos, museos y rincones coloniales.',
                'duration' => '3 horas',
                'location' => 'Zona Colonial',
                'province' => 'Santo Domingo',
                'start_location' => 'Parque Colón',
                'pickup_points' => [
                    'Parque Colón',
                ],
                'price' => 1800,
                'currency' => 'DOP',
                'capacity' => 20,
                'itinerary' => [
                    'Encuentro en Parque Colón',
                    'Catedral Primada de América',
                    'Calle Las Damas',
                    'Alcázar de Colón',
                    'Cierre con recomendaciones locales',
                ],
                'amenities' => [
                    'Guía local',
                    'Paradas fotográficas',
                ],
                'included' => [
                    'Guía turístico',
                    'Recorrido caminando',
                ],
                'not_included' => [
                    'Entradas a museos',
                    'Comida',
                ],
                'requirements' => [
                    'Calzado cómodo',
                    'Agua personal',
                ],
                'cancellation_policy' => 'Cancelación gratuita hasta 12 horas antes.',
                'status' => 'published',
                'published_at' => now(),
                'is_active' => true,
            ],

            [
                'title' => 'Día de playa en Saona',
                'category' => 'Playa',
                'description' => 'Disfruta aguas cristalinas, catamarán, música y almuerzo típico en Isla Saona.',
                'duration' => '8 horas',
                'location' => 'Isla Saona',
                'province' => 'La Altagracia',
                'start_location' => 'Bayahíbe',
                'pickup_points' => [
                    'Punta Cana',
                    'Bayahíbe',
                    'La Romana',
                ],
                'price' => 4200,
                'currency' => 'DOP',
                'capacity' => 30,
                'itinerary' => [
                    'Salida desde Bayahíbe',
                    'Parada en piscina natural',
                    'Llegada a Isla Saona',
                    'Almuerzo típico',
                    'Regreso en catamarán',
                ],
                'amenities' => [
                    'Almuerzo',
                    'Bebidas',
                    'Música',
                    'Transporte marítimo',
                ],
                'included' => [
                    'Almuerzo buffet',
                    'Bebidas nacionales',
                    'Guía acompañante',
                ],
                'not_included' => [
                    'Fotos profesionales',
                    'Propinas',
                ],
                'requirements' => [
                    'Traje de baño',
                    'Toalla',
                    'Protector solar',
                ],
                'cancellation_policy' => 'Cancelación gratuita hasta 48 horas antes.',
                'status' => 'published',
                'published_at' => now(),
                'is_active' => true,
            ],

            [
                'title' => 'Senderismo al Salto de Jimenoa',
                'category' => 'Naturaleza',
                'description' => 'Una caminata rodeada de montañas, ríos y vegetación hasta llegar al famoso Salto de Jimenoa.',
                'duration' => '4 horas',
                'location' => 'Salto de Jimenoa',
                'province' => 'La Vega',
                'start_location' => 'Jarabacoa Centro',
                'pickup_points' => [
                    'Jarabacoa Centro',
                ],
                'price' => 2200,
                'currency' => 'DOP',
                'capacity' => 15,
                'itinerary' => [
                    'Encuentro en Jarabacoa',
                    'Traslado al sendero',
                    'Caminata guiada',
                    'Visita al salto',
                    'Retorno',
                ],
                'amenities' => [
                    'Guía local',
                    'Agua',
                    'Asistencia durante la ruta',
                ],
                'included' => [
                    'Guía',
                    'Entrada local',
                    'Botella de agua',
                ],
                'not_included' => [
                    'Transporte desde otras provincias',
                    'Almuerzo',
                ],
                'requirements' => [
                    'Buena condición física',
                    'Tenis cómodos',
                    'Ropa ligera',
                ],
                'cancellation_policy' => 'Cancelación gratuita hasta 24 horas antes.',
                'status' => 'published',
                'published_at' => now(),
                'is_active' => true,
            ],
        ];

        /**
         * Crear o actualizar experiencias.
         */
        foreach ($experiences as $experience) {
            ProviderExperience::updateOrCreate(
                [
                    'provider_id' => $provider->id,
                    'title' => $experience['title'],
                ],
                array_merge(
                    $experience,
                    [
                        'provider_id' => $provider->id,
                    ]
                )
            );
        }
    }
}