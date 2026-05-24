<?php

namespace App\Services\Provider;

class ProviderInsightService
{
    /**
     * Genera recomendaciones automáticas sin IA.
     *
     * Las recomendaciones salen de reglas simples y datos reales.
     */
    public function generate(array $analytics): array
    {
        $insights = [];

        $summary = $analytics['summary'] ?? [];
        $audience = $analytics['audience'] ?? [];
        $conversion = $analytics['conversion'] ?? [];
        $schedules = $analytics['schedules'] ?? [];
        $demand = $analytics['demand'] ?? [];
        $experiences = $analytics['experiences'] ?? [];
        $loyalty = $analytics['loyalty'] ?? [];
        $warnings = $analytics['warnings'] ?? [];

        $confirmedBookings = (int) ($summary['confirmed_bookings']['value'] ?? 0);
        $lowData = (bool) ($warnings['low_data'] ?? false);

        if ($confirmedBookings === 0) {
            $insights[] = [
                'id' => 'no_confirmed_bookings',
                'type' => 'data_warning',
                'priority' => 'high',
                'confidence' => 1,
                'title' => 'Todavía no hay reservas confirmadas',
                'description' => 'El dashboard ya está conectado, pero necesita reservas confirmadas para generar análisis más precisos.',
                'recommendation' => 'Cuando empieces a confirmar reservas, aquí aparecerán recomendaciones sobre público, fechas, ocupación y marketing.',
                'data_warning' => true,
                'evidence' => [
                    'confirmed_bookings' => 0,
                ],
            ];
        }

        $topCity = $this->firstRelevantItem($audience['top_cities'] ?? []);

        if ($topCity && $topCity['percentage'] >= 35) {
            $insights[] = [
                'id' => 'dominant_city',
                'type' => 'audience',
                'priority' => 'high',
                'confidence' => $this->confidence($topCity['percentage'], $lowData),
                'title' => 'Tu público principal está en ' . $topCity['label'],
                'description' => $topCity['percentage'] . '% de tus reservas confirmadas vienen de ' . $topCity['label'] . '.',
                'recommendation' => 'Crea campañas y mensajes pensados para clientes de esa ciudad.',
                'data_warning' => $lowData,
                'evidence' => $topCity,
            ];
        }

        $topAgeRange = $this->firstRelevantItem(
            items: $audience['age_ranges'] ?? [],
            ignoredLabels: ['Sin edad'],
        );

        if ($topAgeRange && $topAgeRange['percentage'] >= 35) {
            $insights[] = [
                'id' => 'dominant_age_range',
                'type' => 'audience',
                'priority' => 'medium',
                'confidence' => $this->confidence($topAgeRange['percentage'], $lowData),
                'title' => 'Tu rango de edad más fuerte es ' . $topAgeRange['label'],
                'description' => $topAgeRange['percentage'] . '% de tus reservas confirmadas vienen de este rango de edad.',
                'recommendation' => 'Adapta fotos, textos y promociones al estilo de ese público.',
                'data_warning' => $lowData,
                'evidence' => $topAgeRange,
            ];
        }

        foreach (($experiences['top_by_occupancy'] ?? []) as $experience) {
            if (($experience['occupancy_rate'] ?? 0) >= 85 && ($experience['guests_count'] ?? 0) > 0) {
                $insights[] = [
                    'id' => 'open_more_dates_' . $experience['id'],
                    'type' => 'growth',
                    'priority' => 'high',
                    'confidence' => $this->confidence($experience['occupancy_rate'], $lowData),
                    'title' => 'Abre más fechas para ' . $experience['title'],
                    'description' => 'Esta experiencia tiene ' . $experience['occupancy_rate'] . '% de ocupación en el período seleccionado.',
                    'recommendation' => 'Agrega nuevas salidas en los días con mejor ocupación.',
                    'data_warning' => $lowData,
                    'evidence' => [
                        'experience_id' => $experience['id'],
                        'occupancy_rate' => $experience['occupancy_rate'],
                        'guests_count' => $experience['guests_count'],
                    ],
                ];

                break;
            }
        }

        foreach (($schedules['upcoming'] ?? []) as $schedule) {
            if (($schedule['occupancy_rate'] ?? 0) < 50) {
                $insights[] = [
                    'id' => 'promote_schedule_' . $schedule['id'],
                    'type' => 'schedule',
                    'priority' => 'medium',
                    'confidence' => $lowData ? 0.45 : 0.75,
                    'title' => 'Esta salida necesita promoción',
                    'description' => $schedule['experience_title'] . ' tiene ' . $schedule['occupancy_rate'] . '% de ocupación.',
                    'recommendation' => 'Promociona esta fecha con contenido de urgencia o cupos limitados.',
                    'data_warning' => $lowData,
                    'evidence' => [
                        'schedule_id' => $schedule['id'],
                        'experience_id' => $schedule['provider_experience_id'],
                        'occupancy_rate' => $schedule['occupancy_rate'],
                        'booked' => $schedule['booked'],
                        'capacity' => $schedule['capacity'],
                    ],
                ];

                break;
            }
        }

        foreach (($experiences['low_conversion'] ?? []) as $experience) {
            $insights[] = [
                'id' => 'low_favorite_conversion_' . $experience['id'],
                'type' => 'conversion',
                'priority' => 'medium',
                'confidence' => $lowData ? 0.4 : 0.7,
                'title' => 'Mucho interés, pocas reservas',
                'description' => $experience['title'] . ' tiene favoritos, pero baja conversión a reservas confirmadas.',
                'recommendation' => 'Revisa fotos, precio, descripción, fechas disponibles o punto de encuentro.',
                'data_warning' => $lowData,
                'evidence' => [
                    'experience_id' => $experience['id'],
                    'favorites_count' => $experience['favorites_count'],
                    'favorites_to_bookings_rate' => $experience['favorites_to_bookings_rate'],
                ],
            ];

            break;
        }

        $leadRanges = $demand['booking_lead_time']['ranges'] ?? [];
        $topLeadRange = $this->firstRelevantItem(
            items: $leadRanges,
            ignoredLabels: ['Sin fecha'],
        );

        if ($topLeadRange && $topLeadRange['label'] === '3-7 días' && $topLeadRange['percentage'] >= 35) {
            $insights[] = [
                'id' => 'campaign_one_week_before',
                'type' => 'timing',
                'priority' => 'high',
                'confidence' => $this->confidence($topLeadRange['percentage'], $lowData),
                'title' => 'Tus clientes reservan cerca de la fecha',
                'description' => $topLeadRange['percentage'] . '% reserva entre 3 y 7 días antes.',
                'recommendation' => 'Activa campañas una semana antes de cada salida.',
                'data_warning' => $lowData,
                'evidence' => $topLeadRange,
            ];
        }

        if (($loyalty['recurrent_customers_rate'] ?? 0) >= 15) {
            $insights[] = [
                'id' => 'create_vip_offer',
                'type' => 'loyalty',
                'priority' => 'medium',
                'confidence' => $this->confidence($loyalty['recurrent_customers_rate'], $lowData),
                'title' => 'Tienes clientes con potencial de recompra',
                'description' => $loyalty['recurrent_customers_rate'] . '% de tus clientes ya habían reservado antes.',
                'recommendation' => 'Crea ofertas VIP, referidos o acceso temprano para clientes recurrentes.',
                'data_warning' => $lowData,
                'evidence' => [
                    'recurrent_customers_rate' => $loyalty['recurrent_customers_rate'],
                    'recurrent_customers' => $loyalty['recurrent_customers'],
                ],
            ];
        }

        if (empty($insights)) {
            $insights[] = [
                'id' => 'keep_collecting_data',
                'type' => 'general',
                'priority' => 'low',
                'confidence' => 0.4,
                'title' => 'Sigue acumulando datos',
                'description' => 'Todavía no hay suficientes señales fuertes para generar recomendaciones avanzadas.',
                'recommendation' => 'Mantén tus experiencias publicadas, crea fechas disponibles y confirma reservas para activar más análisis.',
                'data_warning' => true,
                'evidence' => [],
            ];
        }

        return $insights;
    }

    private function firstRelevantItem(array $items, array $ignoredLabels = []): ?array
    {
        $filtered = collect($items)
            ->filter(function ($item) use ($ignoredLabels) {
                $label = $item['label'] ?? null;
                $count = (int) ($item['count'] ?? 0);

                return $count > 0 && ! in_array($label, $ignoredLabels, true);
            })
            ->sortByDesc('percentage')
            ->values();

        return $filtered->first();
    }

    private function confidence(float|int $percentage, bool $lowData): float
    {
        $base = min(max($percentage / 100, 0.35), 0.95);

        if ($lowData) {
            return round(max($base - 0.25, 0.35), 2);
        }

        return round($base, 2);
    }
}