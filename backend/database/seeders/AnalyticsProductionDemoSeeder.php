<?php

namespace Database\Seeders;

use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

/**
 * Seeder demo productivo para Analytics de AndanDO.
 *
 * Objetivo:
 * Crear muchos datos realistas para ver cómo se comporta el dashboard
 * estadístico del afiliado como si la app estuviera en producción.
 *
 * Este seeder usa específicamente:
 *
 * provider_id = 1
 *
 * Datos que crea:
 * - Clientes demo
 * - Perfiles demográficos de clientes
 * - Experiencias del proveedor 1
 * - Fechas/salidas para esas experiencias
 * - Reservas con varios estados
 * - Favoritos
 * - Reviews
 *
 * Importante:
 * Este seeder NO borra toda tu base de datos.
 * Solo limpia datos demo creados anteriormente por este mismo seeder:
 * - usuarios con email analytics.client.XXX@andando.test
 * - experiencias demo del proveedor 1 con títulos definidos aquí
 * - reservas con booking_code que empieza por ANDO-DEMO-
 *
 * Así puedes correrlo varias veces sin duplicar datos demo.
 */
class AnalyticsProductionDemoSeeder extends Seeder
{
    /**
     * ID del proveedor que se usará para analytics.
     *
     * El usuario pidió específicamente usar provider_id = 1.
     */
    private const PROVIDER_ID = 1;

    /**
     * Cantidad de clientes demo a crear.
     */
    private const CLIENTS_COUNT = 180;

    /**
     * Cantidad de reservas demo a crear.
     */
    private const BOOKINGS_COUNT = 1000;

    /**
     * Cantidad de favoritos demo a crear.
     */
    private const FAVORITES_COUNT = 500;

    /**
     * Cantidad aproximada de reviews demo a crear.
     */
    private const REVIEWS_TARGET = 300;

    /**
     * Ejecuta el seeder.
     */
    public function run(): void
    {
        DB::transaction(function () {
            $provider = DB::table('providers')
                ->where('id', self::PROVIDER_ID)
                ->first();

            if (! $provider) {
                throw new RuntimeException(
                    'No existe providers.id = 1. Crea primero el proveedor 1 o ajusta PROVIDER_ID en el seeder.'
                );
            }

            /**
             * Aseguramos que el proveedor 1 esté aprobado.
             *
             * Esto es necesario porque el router y el endpoint de analytics
             * solo permiten entrar si el proveedor está approved.
             */
            DB::table('providers')
                ->where('id', self::PROVIDER_ID)
                ->update([
                    'status' => 'approved',
                    'approved_at' => now(),
                    'updated_at' => now(),
                ]);

            /**
             * También aseguramos que el usuario dueño del proveedor
             * tenga type = provider.
             */
            if (! empty($provider->user_id)) {
                DB::table('users')
                    ->where('id', $provider->user_id)
                    ->update([
                        'type' => 'provider',
                        'updated_at' => now(),
                    ]);
            }

            $experienceDefinitions = $this->experienceDefinitions();

            $this->cleanPreviousDemoData($experienceDefinitions);

            $clientIds = $this->createClients();

            $experiences = $this->createExperiences($experienceDefinitions);

            $schedules = $this->createSchedules($experiences);

            $bookings = $this->createBookings(
                clientIds: $clientIds,
                experiences: $experiences,
                schedules: $schedules,
            );

            $this->createFavorites(
                clientIds: $clientIds,
                experiences: $experiences,
            );

            $this->createReviews(
                clientIds: $clientIds,
                bookings: $bookings,
            );
        });
    }

    /**
     * Elimina datos demo previos para que el seeder sea repetible.
     *
     * Esto evita duplicados cuando vuelvas a correr:
     *
     * php artisan db:seed --class=AnalyticsProductionDemoSeeder
     */
    private function cleanPreviousDemoData(array $experienceDefinitions): void
    {
        $demoEmails = DB::table('users')
            ->where('email', 'like', 'analytics.client.%@andando.test')
            ->pluck('id');

        $demoTitles = collect($experienceDefinitions)
            ->pluck('title')
            ->all();

        $demoExperienceIds = DB::table('provider_experiences')
            ->where('provider_id', self::PROVIDER_ID)
            ->whereIn('title', $demoTitles)
            ->pluck('id');

        $demoBookingIds = DB::table('provider_bookings')
            ->where('booking_code', 'like', 'ANDO-DEMO-%')
            ->pluck('id');

        /**
         * Primero eliminamos reviews porque dependen de bookings.
         */
        DB::table('provider_reviews')
            ->where('provider_id', self::PROVIDER_ID)
            ->where(function ($query) use ($demoBookingIds, $demoEmails) {
                $query
                    ->whereIn('provider_booking_id', $demoBookingIds)
                    ->orWhereIn('user_id', $demoEmails);
            })
            ->delete();

        /**
         * Eliminamos favoritos demo.
         */
        DB::table('customer_favorite_experiences')
            ->where(function ($query) use ($demoEmails, $demoExperienceIds) {
                $query
                    ->whereIn('user_id', $demoEmails)
                    ->orWhereIn('provider_experience_id', $demoExperienceIds);
            })
            ->delete();

        /**
         * Eliminamos reservas demo.
         */
        DB::table('provider_bookings')
            ->where(function ($query) use ($demoExperienceIds) {
                $query
                    ->where('booking_code', 'like', 'ANDO-DEMO-%')
                    ->orWhereIn('provider_experience_id', $demoExperienceIds);
            })
            ->delete();

        /**
         * Eliminamos fechas demo.
         */
        DB::table('provider_experience_schedules')
            ->whereIn('provider_experience_id', $demoExperienceIds)
            ->delete();

        /**
         * Eliminamos series demo si existieran.
         */
        DB::table('provider_experience_schedule_series')
            ->whereIn('provider_experience_id', $demoExperienceIds)
            ->delete();

        /**
         * Eliminamos experiencias demo.
         */
        DB::table('provider_experiences')
            ->whereIn('id', $demoExperienceIds)
            ->delete();

        /**
         * Eliminamos perfiles y usuarios demo.
         */
        DB::table('client_profiles')
            ->whereIn('user_id', $demoEmails)
            ->delete();

        DB::table('users')
            ->whereIn('id', $demoEmails)
            ->delete();
    }

    /**
     * Crea clientes demo con perfiles demográficos.
     *
     * Estos datos alimentan:
     * - edad
     * - ciudades
     * - países
     * - nacionalidad
     * - idioma
     * - moneda preferida
     */
    private function createClients(): array
    {
        $clientIds = [];

        $cities = [
            ['Santo Domingo', 'República Dominicana', 'Dominicana', 'es', 42],
            ['Santiago', 'República Dominicana', 'Dominicana', 'es', 18],
            ['La Romana', 'República Dominicana', 'Dominicana', 'es', 8],
            ['Punta Cana', 'República Dominicana', 'Dominicana', 'es', 10],
            ['San Pedro de Macorís', 'República Dominicana', 'Dominicana', 'es', 5],
            ['Nueva York', 'Estados Unidos', 'Dominicana', 'es', 7],
            ['Miami', 'Estados Unidos', 'Estadounidense', 'en', 5],
            ['Madrid', 'España', 'Española', 'es', 3],
            ['Montreal', 'Canadá', 'Canadiense', 'fr', 2],
        ];

        $genders = ['masculino', 'femenino', 'otro', 'prefiero_no_decir'];

        for ($i = 1; $i <= self::CLIENTS_COUNT; $i++) {
            $cityData = $this->weightedRow($cities);

            $name = $this->fakeName($i);
            $email = sprintf('analytics.client.%03d@andando.test', $i);

            $userId = DB::table('users')->insertGetId([
                'name' => $name,
                'email' => $email,
                'type' => 'customer',
                'phone' => '809' . random_int(1000000, 9999999),
                'email_verified_at' => now(),
                'password' => Hash::make('*centro22'),
                'remember_token' => null,
                'created_at' => now()->subDays(random_int(10, 420)),
                'updated_at' => now(),
            ]);

            /**
             * Buscamos que el rango 25-34 sea dominante,
             * pero con variedad suficiente para que las gráficas se vean reales.
             */
            $age = $this->weightedChoice([
                [random_int(18, 24), 22],
                [random_int(25, 34), 46],
                [random_int(35, 44), 18],
                [random_int(45, 54), 9],
                [random_int(55, 68), 5],
            ], 1);

            DB::table('client_profiles')->insert([
                'user_id' => $userId,
                'avatar_path' => null,
                'birth_date' => now()->subYears($age)->subDays(random_int(0, 360))->toDateString(),
                'gender' => $genders[array_rand($genders)],
                'nationality' => $cityData[2],
                'residence_city' => $cityData[0],
                'preferred_currency' => $cityData[1] === 'Estados Unidos' ? 'USD' : 'DOP',
                'language' => $cityData[3],
                'country' => $cityData[1],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $clientIds[] = $userId;
        }

        return $clientIds;
    }

    /**
     * Crea experiencias demo del proveedor 1.
     *
     * Estas experiencias tienen distintas categorías, precios y capacidades
     * para que analytics pueda mostrar rankings variados.
     */
    private function createExperiences(array $definitions): array
    {
        $experiences = [];

        foreach ($definitions as $index => $definition) {
            $experienceId = DB::table('provider_experiences')->insertGetId([
                'provider_id' => self::PROVIDER_ID,
                'title' => $definition['title'],
                'category' => $definition['category'],
                'description' => $definition['description'],
                'duration' => $definition['duration'],
                'location' => $definition['location'],
                'province' => $definition['province'],
                'start_location' => $definition['start_location'],
                'pickup_points' => json_encode($definition['pickup_points']),
                'price' => $definition['price'],
                'currency' => 'DOP',
                'capacity' => $definition['capacity'],
                'itinerary' => json_encode($definition['itinerary']),
                'amenities' => json_encode($definition['amenities']),
                'included' => json_encode($definition['included']),
                'not_included' => json_encode($definition['not_included']),
                'requirements' => json_encode($definition['requirements']),
                'cancellation_policy' => $definition['cancellation_policy'],
                'status' => $definition['status'],
                'is_active' => true,
                'published_at' => now()->subDays(random_int(45, 220)),
                'created_at' => now()->subDays(260 - ($index * 7)),
                'updated_at' => now(),
            ]);

            $experiences[] = [
                'id' => $experienceId,
                ...$definition,
            ];
        }

        return $experiences;
    }

    /**
     * Crea fechas/salidas para cada experiencia.
     *
     * Genera fechas pasadas y futuras para que se puedan ver:
     * - próximas salidas
     * - ocupación por día
     * - fechas con baja ocupación
     * - fechas casi llenas
     */
    private function createSchedules(array $experiences): array
    {
        $schedules = [];

        foreach ($experiences as $experience) {
            /**
             * 28 fechas por experiencia.
             * Con 10 experiencias son aproximadamente 280 salidas.
             */
            for ($i = -14; $i <= 13; $i++) {
                $startsAt = now()
                    ->copy()
                    ->addDays($i * 7 + random_int(-2, 2))
                    ->setTime(
                        random_int(6, 9),
                        [0, 15, 30, 45][array_rand([0, 15, 30, 45])]
                    );

                $isPast = $startsAt->isPast();

                $status = $isPast
                    ? $this->weightedChoice([
                        ['completed', 82],
                        ['cancelled', 8],
                        ['active', 10],
                    ], 1)
                    : $this->weightedChoice([
                        ['active', 86],
                        ['paused', 8],
                        ['cancelled', 6],
                    ], 1);

                $capacity = max(8, (int) ($experience['capacity'] + random_int(-4, 8)));

                $scheduleId = DB::table('provider_experience_schedules')->insertGetId([
                    'provider_id' => self::PROVIDER_ID,
                    'provider_experience_id' => $experience['id'],
                    'series_id' => null,
                    'starts_at' => $startsAt->toDateTimeString(),
                    'ends_at' => $startsAt->copy()->addHours(random_int(5, 10))->toDateTimeString(),
                    'timezone' => 'America/Santo_Domingo',
                    'capacity' => $capacity,
                    'price' => $experience['price'],
                    'currency' => 'DOP',
                    'status' => $status,
                    'notes' => $status === 'active'
                        ? 'Salida disponible para reservas.'
                        : null,
                    'cancellation_reason' => $status === 'cancelled'
                        ? 'Cancelada por condiciones operativas o clima.'
                        : null,
                    'created_at' => $startsAt->copy()->subDays(random_int(35, 120))->toDateTimeString(),
                    'updated_at' => now(),
                ]);

                $schedules[] = [
                    'id' => $scheduleId,
                    'provider_experience_id' => $experience['id'],
                    'experience_title' => $experience['title'],
                    'category' => $experience['category'],
                    'starts_at' => $startsAt,
                    'capacity' => $capacity,
                    'price' => $experience['price'],
                    'status' => $status,
                ];
            }
        }

        return $schedules;
    }

    /**
     * Crea reservas realistas.
     *
     * Estados usados:
     * - confirmed: cuentan para analytics como reservas válidas
     * - pending: aparecen como interés/reservas no confirmadas
     * - cancelled: alimentan tasa de cancelación
     * - completed: sirven como histórico, aunque analytics actual se centra en confirmed
     */
    private function createBookings(
        array $clientIds,
        array $experiences,
        array $schedules,
    ): array {
        $bookings = [];

        for ($i = 1; $i <= self::BOOKINGS_COUNT; $i++) {
            $schedule = $this->pickScheduleWithBias($schedules);

            $experience = collect($experiences)
                ->firstWhere('id', $schedule['provider_experience_id']);

            /**
             * Cantidad de personas por reserva.
             *
             * Esto respeta tu regla:
             * una persona puede reservar para 1 o para varias personas.
             */
            $guests = $this->weightedChoice([
                [1, 38],
                [2, 32],
                [3, 15],
                [4, 11],
                [5, 4],
            ], 1);

            $unitPrice = (float) $schedule['price'];
            $totalAmount = $unitPrice * $guests;

            /**
             * Simulamos comisión de AndanDO.
             * El proveedor gana aproximadamente 86%.
             */
            $providerEarning = round($totalAmount * 0.86, 2);

            $status = $this->weightedChoice([
                ['confirmed', 72],
                ['pending', 12],
                ['cancelled', 10],
                ['completed', 6],
            ], 1);

            /**
             * La reserva se crea días antes de la salida.
             * Esto alimenta la métrica de anticipación de reserva.
             */
            $leadDays = $this->weightedChoice([
                [random_int(0, 2), 18],
                [random_int(3, 7), 42],
                [random_int(8, 14), 25],
                [random_int(15, 35), 15],
            ], 1);

            $createdAt = $schedule['starts_at']
                ->copy()
                ->subDays($leadDays)
                ->subHours(random_int(0, 18));

            /**
             * Si por ser una salida futura la fecha de creación queda en el futuro,
             * la traemos a una fecha reciente válida.
             */
            if ($createdAt->isFuture()) {
                $createdAt = now()
                    ->copy()
                    ->subDays(random_int(0, 28))
                    ->setTime(random_int(8, 22), random_int(0, 59));
            }

            /**
             * Si la reserva está cancelada, dejamos la ganancia en 0.
             * Si está pendiente, también dejamos ganancia en 0 porque no hay pago.
             */
            $earningForStatus = in_array($status, ['confirmed', 'completed'], true)
                ? $providerEarning
                : 0;

            $totalForStatus = in_array($status, ['confirmed', 'completed'], true)
                ? $totalAmount
                : 0;

            $clientId = $clientIds[array_rand($clientIds)];

            $bookingId = DB::table('provider_bookings')->insertGetId([
                'provider_id' => self::PROVIDER_ID,
                'provider_experience_id' => $schedule['provider_experience_id'],
                'provider_experience_schedule_id' => $schedule['id'],
                'user_id' => $clientId,
                'booking_code' => sprintf('ANDO-DEMO-%05d', $i),
                'customer_name' => null,
                'customer_phone' => null,
                'customer_email' => null,
                'booking_date' => $schedule['starts_at']->toDateTimeString(),
                'guests_count' => $guests,
                'unit_price' => $unitPrice,
                'total_amount' => $totalForStatus,
                'provider_earning' => $earningForStatus,
                'status' => $status,
                'created_at' => $createdAt->toDateTimeString(),
                'updated_at' => $createdAt->copy()->addHours(random_int(1, 72))->toDateTimeString(),
            ]);

            $bookings[] = [
                'id' => $bookingId,
                'user_id' => $clientId,
                'provider_experience_id' => $schedule['provider_experience_id'],
                'provider_experience_schedule_id' => $schedule['id'],
                'experience_title' => $experience['title'] ?? 'Experiencia',
                'status' => $status,
                'rating_candidate' => in_array($status, ['confirmed', 'completed'], true),
                'created_at' => $createdAt,
            ];
        }

        return $bookings;
    }

    /**
     * Crea favoritos de clientes sobre experiencias.
     *
     * Esto alimenta:
     * - favoritos por experiencia
     * - favoritos convertidos en reserva
     * - experiencias con mucho interés y pocas reservas
     */
    private function createFavorites(array $clientIds, array $experiences): void
    {
        $created = [];
        $attempts = 0;

        while (count($created) < self::FAVORITES_COUNT && $attempts < self::FAVORITES_COUNT * 6) {
            $attempts++;

            $clientId = $clientIds[array_rand($clientIds)];
            $experience = $this->weightedExperienceForFavorites($experiences);

            $key = $clientId . '-' . $experience['id'];

            if (isset($created[$key])) {
                continue;
            }

            $created[$key] = true;

            DB::table('customer_favorite_experiences')->insert([
                'user_id' => $clientId,
                'provider_experience_id' => $experience['id'],
                'created_at' => now()->subDays(random_int(0, 180))->setTime(random_int(7, 23), random_int(0, 59)),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Crea reviews para reservas confirmadas/completadas.
     *
     * Aunque el analytics actual no usa reviews todavía,
     * el dashboard y futuras métricas de calidad sí pueden usarlas.
     */
    private function createReviews(array $clientIds, array $bookings): void
    {
        $eligibleBookings = collect($bookings)
            ->where('rating_candidate', true)
            ->shuffle()
            ->take(self::REVIEWS_TARGET);

        foreach ($eligibleBookings as $booking) {
            $rating = $this->weightedChoice([
                [5, 56],
                [4, 30],
                [3, 9],
                [2, 3],
                [1, 2],
            ], 1);

            DB::table('provider_reviews')->insert([
                'provider_id' => self::PROVIDER_ID,
                'provider_booking_id' => $booking['id'],
                'user_id' => $booking['user_id'],
                'rating' => $rating,
                'comment' => $this->reviewComment($rating, $booking['experience_title']),
                'is_visible' => true,
                'created_at' => $booking['created_at']->copy()->addDays(random_int(1, 10))->toDateTimeString(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Experiencias demo del proveedor.
     *
     * Tienen variedad de categoría y precio para que el dashboard muestre
     * comportamiento distinto por producto.
     */
    private function experienceDefinitions(): array
    {
        return [
            [
                'title' => 'Aventura en Samaná',
                'category' => 'Aventura',
                'description' => 'Excursión completa con playa, naturaleza, miradores y experiencia local.',
                'duration' => 'Día completo',
                'location' => 'Samaná',
                'province' => 'Samaná',
                'start_location' => 'Punto de encuentro principal en Santo Domingo.',
                'pickup_points' => ['Santo Domingo', 'Autopista Las Américas', 'Samaná centro'],
                'price' => 3500,
                'capacity' => 24,
                'status' => 'published',
                'itinerary' => ['Salida temprano', 'Parada panorámica', 'Playa', 'Almuerzo', 'Regreso'],
                'amenities' => ['Transporte', 'Guía', 'Música', 'Agua'],
                'included' => ['Transporte ida y vuelta', 'Almuerzo', 'Guía local'],
                'not_included' => ['Bebidas alcohólicas', 'Propinas'],
                'requirements' => ['Ropa cómoda', 'Protector solar'],
                'cancellation_policy' => 'Cancelación gratis hasta 48 horas antes.',
            ],
            [
                'title' => 'Isla Saona Premium',
                'category' => 'Playa',
                'description' => 'Día de playa, catamarán y piscina natural en Isla Saona.',
                'duration' => 'Día completo',
                'location' => 'Bayahíbe',
                'province' => 'La Altagracia',
                'start_location' => 'Salida desde Santo Domingo y Punta Cana.',
                'pickup_points' => ['Santo Domingo', 'La Romana', 'Bayahíbe'],
                'price' => 4200,
                'capacity' => 32,
                'status' => 'published',
                'itinerary' => ['Bayahíbe', 'Catamarán', 'Piscina natural', 'Isla Saona', 'Regreso'],
                'amenities' => ['Catamarán', 'Buffet', 'Guía', 'Animación'],
                'included' => ['Transporte', 'Almuerzo buffet', 'Bebidas no alcohólicas'],
                'not_included' => ['Fotos profesionales', 'Souvenirs'],
                'requirements' => ['Traje de baño', 'Toalla'],
                'cancellation_policy' => 'Cancelación gratis hasta 72 horas antes.',
            ],
            [
                'title' => 'Ruta Cultural Colonial',
                'category' => 'Cultura',
                'description' => 'Tour histórico por la Ciudad Colonial con guía local.',
                'duration' => '4 horas',
                'location' => 'Zona Colonial',
                'province' => 'Santo Domingo',
                'start_location' => 'Parque Colón.',
                'pickup_points' => ['Parque Colón', 'Museo de las Casas Reales'],
                'price' => 1800,
                'capacity' => 18,
                'status' => 'published',
                'itinerary' => ['Parque Colón', 'Catedral', 'Calle Las Damas', 'Museos', 'Café local'],
                'amenities' => ['Guía', 'Entrada a museos', 'Café'],
                'included' => ['Guía certificado', 'Entradas seleccionadas'],
                'not_included' => ['Comidas completas'],
                'requirements' => ['Zapatos cómodos'],
                'cancellation_policy' => 'Cancelación gratis hasta 24 horas antes.',
            ],
            [
                'title' => 'Montaña Redonda Sunset',
                'category' => 'Naturaleza',
                'description' => 'Experiencia de montaña con vistas, columpios y atardecer.',
                'duration' => '6 horas',
                'location' => 'Miches',
                'province' => 'El Seibo',
                'start_location' => 'Salida desde Santo Domingo o Punta Cana.',
                'pickup_points' => ['Santo Domingo', 'Punta Cana', 'Miches'],
                'price' => 2900,
                'capacity' => 22,
                'status' => 'published',
                'itinerary' => ['Salida', 'Subida a montaña', 'Fotos', 'Atardecer', 'Regreso'],
                'amenities' => ['Transporte 4x4', 'Guía', 'Agua'],
                'included' => ['Transporte', 'Entrada', 'Guía'],
                'not_included' => ['Almuerzo'],
                'requirements' => ['Ropa cómoda'],
                'cancellation_policy' => 'Cancelación gratis hasta 48 horas antes.',
            ],
            [
                'title' => 'Cascadas de Jarabacoa',
                'category' => 'Ecoturismo',
                'description' => 'Ruta ecológica con cascadas, senderismo suave y almuerzo típico.',
                'duration' => 'Día completo',
                'location' => 'Jarabacoa',
                'province' => 'La Vega',
                'start_location' => 'Salida desde Santiago y Santo Domingo.',
                'pickup_points' => ['Santiago', 'La Vega', 'Jarabacoa'],
                'price' => 3100,
                'capacity' => 20,
                'status' => 'published',
                'itinerary' => ['Sendero', 'Cascada', 'Almuerzo', 'Mirador', 'Regreso'],
                'amenities' => ['Guía', 'Almuerzo', 'Agua'],
                'included' => ['Transporte', 'Almuerzo', 'Entrada'],
                'not_included' => ['Zapatos acuáticos'],
                'requirements' => ['Condición física básica'],
                'cancellation_policy' => 'Cancelación gratis hasta 48 horas antes.',
            ],
            [
                'title' => 'Bahía de las Águilas Express',
                'category' => 'Playa',
                'description' => 'Escapada a una de las playas más hermosas del Caribe.',
                'duration' => 'Fin de semana',
                'location' => 'Pedernales',
                'province' => 'Pedernales',
                'start_location' => 'Salida desde Santo Domingo.',
                'pickup_points' => ['Santo Domingo', 'Baní', 'Barahona', 'Pedernales'],
                'price' => 6800,
                'capacity' => 28,
                'status' => 'published',
                'itinerary' => ['Viaje sur', 'Hospedaje', 'Bahía', 'Paseo en bote', 'Regreso'],
                'amenities' => ['Transporte', 'Hospedaje', 'Guía'],
                'included' => ['Transporte', 'Hospedaje básico', 'Desayuno'],
                'not_included' => ['Cena', 'Bebidas alcohólicas'],
                'requirements' => ['Documento de identidad'],
                'cancellation_policy' => 'Cancelación gratis hasta 5 días antes.',
            ],
            [
                'title' => 'Tour Gastronómico Dominicano',
                'category' => 'Gastronomía',
                'description' => 'Ruta de sabores locales, comida típica y experiencias de barrio.',
                'duration' => '5 horas',
                'location' => 'Santo Domingo',
                'province' => 'Santo Domingo',
                'start_location' => 'Ágora Mall.',
                'pickup_points' => ['Ágora Mall', 'Zona Colonial', 'Gazcue'],
                'price' => 2400,
                'capacity' => 16,
                'status' => 'published',
                'itinerary' => ['Desayuno típico', 'Mercado local', 'Dulces', 'Café', 'Cena ligera'],
                'amenities' => ['Degustaciones', 'Guía', 'Agua'],
                'included' => ['Degustaciones', 'Guía local'],
                'not_included' => ['Compras personales'],
                'requirements' => ['Informar alergias'],
                'cancellation_policy' => 'Cancelación gratis hasta 24 horas antes.',
            ],
            [
                'title' => 'Dunas de Baní y Playa Salinas',
                'category' => 'Aventura',
                'description' => 'Ruta de dunas, fotos, playa y almuerzo frente al mar.',
                'duration' => 'Día completo',
                'location' => 'Baní',
                'province' => 'Peravia',
                'start_location' => 'Salida desde Santo Domingo.',
                'pickup_points' => ['Santo Domingo', 'Baní', 'Salinas'],
                'price' => 2700,
                'capacity' => 22,
                'status' => 'published',
                'itinerary' => ['Dunas', 'Fotos', 'Playa Salinas', 'Almuerzo', 'Regreso'],
                'amenities' => ['Transporte', 'Guía', 'Agua'],
                'included' => ['Transporte', 'Entrada', 'Guía'],
                'not_included' => ['Almuerzo'],
                'requirements' => ['Protector solar'],
                'cancellation_policy' => 'Cancelación gratis hasta 48 horas antes.',
            ],
            [
                'title' => 'Noche Romántica en Altos de Chavón',
                'category' => 'Romántico',
                'description' => 'Experiencia nocturna para parejas con cena y paseo cultural.',
                'duration' => '6 horas',
                'location' => 'Altos de Chavón',
                'province' => 'La Romana',
                'start_location' => 'Salida desde Santo Domingo.',
                'pickup_points' => ['Santo Domingo', 'La Romana'],
                'price' => 5200,
                'capacity' => 14,
                'status' => 'published',
                'itinerary' => ['Salida', 'Paseo cultural', 'Cena', 'Fotos', 'Regreso'],
                'amenities' => ['Cena', 'Guía', 'Transporte'],
                'included' => ['Transporte', 'Cena seleccionada'],
                'not_included' => ['Bebidas premium'],
                'requirements' => ['Vestimenta casual elegante'],
                'cancellation_policy' => 'Cancelación gratis hasta 72 horas antes.',
            ],
            [
                'title' => 'Family Day Boca Chica',
                'category' => 'Familiar',
                'description' => 'Día familiar de playa con actividades para niños y adultos.',
                'duration' => 'Día completo',
                'location' => 'Boca Chica',
                'province' => 'Santo Domingo',
                'start_location' => 'Salida desde Santo Domingo Este.',
                'pickup_points' => ['Megacentro', 'Boca Chica'],
                'price' => 1600,
                'capacity' => 35,
                'status' => 'published',
                'itinerary' => ['Llegada', 'Actividades', 'Almuerzo', 'Playa', 'Regreso'],
                'amenities' => ['Juegos', 'Guía', 'Agua'],
                'included' => ['Transporte', 'Animación'],
                'not_included' => ['Almuerzo'],
                'requirements' => ['Menores acompañados de adulto'],
                'cancellation_policy' => 'Cancelación gratis hasta 24 horas antes.',
            ],
        ];
    }

    /**
     * Escoge una salida con sesgo hacia experiencias fuertes.
     *
     * Esto hace que analytics muestre productos ganadores y productos débiles,
     * como ocurre en producción.
     */
    private function pickScheduleWithBias(array $schedules): array
    {
        $weighted = [];

        foreach ($schedules as $schedule) {
            $weight = match ($schedule['category']) {
                'Playa' => 18,
                'Aventura' => 16,
                'Naturaleza' => 13,
                'Ecoturismo' => 12,
                'Cultura' => 7,
                'Gastronomía' => 8,
                'Romántico' => 5,
                'Familiar' => 9,
                default => 10,
            };

            if ($schedule['status'] === 'cancelled') {
                $weight = 1;
            }

            for ($i = 0; $i < $weight; $i++) {
                $weighted[] = $schedule;
            }
        }

        return $weighted[array_rand($weighted)];
    }

    /**
     * Escoge experiencias para favoritos.
     *
     * Damos más favoritos a Cultura y Romántico para simular casos de:
     * "mucho interés, pocas reservas".
     */
    private function weightedExperienceForFavorites(array $experiences): array
    {
        $weighted = [];

        foreach ($experiences as $experience) {
            $weight = match ($experience['category']) {
                'Cultura' => 22,
                'Romántico' => 18,
                'Playa' => 16,
                'Aventura' => 14,
                'Naturaleza' => 10,
                'Ecoturismo' => 9,
                'Gastronomía' => 12,
                'Familiar' => 8,
                default => 10,
            };

            for ($i = 0; $i < $weight; $i++) {
                $weighted[] = $experience;
            }
        }

        return $weighted[array_rand($weighted)];
    }

    /**
     * Elige un valor basado en pesos.
     *
     * Formato esperado:
     *
     * [
     *   ['confirmed', 70],
     *   ['pending', 20],
     *   ['cancelled', 10],
     * ]
     *
     * $valueIndex indica en qué posición está el valor.
     * El peso siempre debe estar en la última posición del item.
     */
    private function weightedChoice(array $items, int $valueIndex)
    {
        $total = array_sum(array_map(fn ($item) => $item[array_key_last($item)], $items));
        $random = random_int(1, $total);

        $current = 0;

        foreach ($items as $item) {
            $weight = $item[array_key_last($item)];
            $current += $weight;

            if ($random <= $current) {
                return $item[$valueIndex - 1];
            }
        }

        return $items[0][$valueIndex - 1];
    }

        /**
     * Elige una fila completa basada en pesos.
     *
     * Este método sirve cuando necesitamos obtener el array completo,
     * no solo un valor dentro del array.
     *
     * Ejemplo de uso:
     *
     * [
     *     ['Santo Domingo', 'República Dominicana', 'Dominicana', 'es', 42],
     *     ['Santiago', 'República Dominicana', 'Dominicana', 'es', 18],
     * ]
     *
     * El último valor de cada fila es el peso.
     *
     * Si Santo Domingo tiene peso 42 y Santiago peso 18,
     * Santo Domingo tendrá más probabilidad de ser seleccionado.
     *
     * Retorna la fila completa:
     *
     * ['Santo Domingo', 'República Dominicana', 'Dominicana', 'es', 42]
     *
     * Así luego podemos usar:
     *
     * $cityData[0] = ciudad
     * $cityData[1] = país
     * $cityData[2] = nacionalidad
     * $cityData[3] = idioma
     */
    private function weightedRow(array $items): array
    {
        $total = array_sum(
            array_map(
                fn ($item) => (int) $item[array_key_last($item)],
                $items
            )
        );

        $random = random_int(1, $total);
        $current = 0;

        foreach ($items as $item) {
            $weight = (int) $item[array_key_last($item)];
            $current += $weight;

            if ($random <= $current) {
                return $item;
            }
        }

        return $items[0];
    }

    /**
     * Genera nombres simples y legibles para clientes demo.
     */
    private function fakeName(int $index): string
    {
        $firstNames = [
            'Jean', 'Kevin', 'María', 'Ana', 'Luis', 'Carlos', 'Laura', 'Paola',
            'José', 'Miguel', 'Carolina', 'Gabriel', 'Sofía', 'Raúl', 'Daniela',
            'Ricardo', 'Patricia', 'Manuel', 'Valeria', 'Andrés',
        ];

        $lastNames = [
            'Adames', 'Brea', 'Gómez', 'Rodríguez', 'Pérez', 'Martínez',
            'Fernández', 'Santos', 'Ramírez', 'Torres', 'Méndez', 'Castillo',
            'Reyes', 'Vargas', 'Morales', 'Núñez',
        ];

        return $firstNames[array_rand($firstNames)]
            . ' '
            . $lastNames[array_rand($lastNames)]
            . ' '
            . str_pad((string) $index, 3, '0', STR_PAD_LEFT);
    }

    /**
     * Comentario simple para reviews.
     */
    private function reviewComment(int $rating, string $experienceTitle): string
    {
        if ($rating >= 5) {
            return "Excelente experiencia en {$experienceTitle}. Todo estuvo muy organizado.";
        }

        if ($rating === 4) {
            return "Muy buena experiencia en {$experienceTitle}. Repetiría con algunos ajustes menores.";
        }

        if ($rating === 3) {
            return "La experiencia estuvo bien, pero hay puntos que se pueden mejorar.";
        }

        if ($rating === 2) {
            return "La experiencia no cumplió totalmente mis expectativas.";
        }

        return "No tuve una buena experiencia. Deben mejorar la organización.";
    }
}