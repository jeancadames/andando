import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/provider_bottom_nav.dart';
import '../../../auth/application/auth_controller.dart';
import '../models/provider_analytics_model.dart';
import '../services/provider_analytics_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Pantalla de análisis estadístico del afiliado.
///
/// Esta pantalla consume datos reales desde:
///
/// GET /api/provider/analytics
///
/// Importante:
/// - No usa datos quemados.
/// - No modifica reservas, experiencias ni clientes.
/// - Solo lee estadísticas ya calculadas por Laravel.
/// - Las recomendaciones vienen del backend, generadas por reglas.
/// - Usa el navbar real compartido del afiliado: ProviderBottomNav.
class ProviderAnalyticsScreen extends StatefulWidget {
  const ProviderAnalyticsScreen({
    super.key,
    required this.authController,
  });

  /// Controlador global de autenticación.
  ///
  /// De aquí tomamos el token real del afiliado autenticado.
  /// Ese token se envía al backend usando:
  ///
  /// Authorization: Bearer TOKEN_DEL_AFILIADO
  final AuthController authController;

  @override
  State<ProviderAnalyticsScreen> createState() =>
      _ProviderAnalyticsScreenState();
}

class _ProviderAnalyticsScreenState extends State<ProviderAnalyticsScreen> {
  /// Servicio que llama al endpoint de analytics.
  ///
  /// Esta clase consulta Laravel y convierte el JSON en modelos de Dart.
  final ProviderAnalyticsService _service = ProviderAnalyticsService();

  /// Futuro principal de la pantalla.
  ///
  /// Flutter usa este Future para saber si debe mostrar:
  /// - cargando
  /// - error
  /// - datos
  late Future<ProviderAnalyticsModel> _analyticsFuture;

  /// Período actualmente seleccionado.
  ///
  /// Valores soportados por Laravel:
  /// - 7d
  /// - 30d
  /// - 90d
  /// - year
  /// - custom
  String _selectedPeriod = '30d';

  /// Experiencia seleccionada.
  ///
  /// null significa:
  /// Todas las experiencias.
  int? _selectedExperienceId;

  @override
  void initState() {
    super.initState();

    // Carga inicial del dashboard estadístico.
    _analyticsFuture = _loadAnalytics();
  }

  /// Carga los datos reales desde el backend.
  ///
  /// Esta función se usa tanto para la primera carga como para refrescar.
  Future<ProviderAnalyticsModel> _loadAnalytics() {
    return _service.getAnalytics(
      token: widget.authController.token,
      period: _selectedPeriod,
      experienceId: _selectedExperienceId,
    );
  }

  /// Refresca la pantalla manualmente.
  ///
  /// El usuario podrá hacer pull-to-refresh.
  Future<void> _refreshAnalytics() async {
    setState(() {
      _analyticsFuture = _loadAnalytics();
    });

    await _analyticsFuture;
  }

  /// Cambia el período de análisis.
  ///
  /// Cada vez que el usuario toca un filtro, volvemos a consultar el backend.
  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _analyticsFuture = _loadAnalytics();
    });
  }

  /// Cambia la experiencia filtrada.
  ///
  /// Si el valor es null, se muestran todas las experiencias.
  void _changeExperience(int? experienceId) {
    setState(() {
      _selectedExperienceId = experienceId;
      _analyticsFuture = _loadAnalytics();
    });
  }

  /// Navega a otra pantalla principal del afiliado.
  ///
  /// Usamos RouteNames porque tu proyecto ya centraliza los nombres de rutas.
  ///
  /// Así evitamos escribir rutas como texto suelto, por ejemplo:
  /// /provider/dashboard
  ///
  /// y navegamos de forma más mantenible:
  /// RouteNames.providerDashboard
  void _goToNamed(String routeName) {
    context.goNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AnalyticsColors.background,
      body: SafeArea(
        child: FutureBuilder<ProviderAnalyticsModel>(
          future: _analyticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _AnalyticsLoading();
            }

            if (snapshot.hasError) {
              return _AnalyticsError(
                message: snapshot.error.toString(),
                onRetry: _refreshAnalytics,
              );
            }

            final analytics = snapshot.data;

            if (analytics == null) {
              return _AnalyticsError(
                message: 'No se pudo cargar el análisis estadístico.',
                onRetry: _refreshAnalytics,
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshAnalytics,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _AnalyticsHeader(
                    analytics: analytics,
                    selectedPeriod: _selectedPeriod,
                    selectedExperienceId: _selectedExperienceId,
                    onPeriodChanged: _changePeriod,
                    onExperienceChanged: _changeExperience,
                  ),
                  Padding(
                    // Dejamos espacio inferior suficiente para que el navbar
                    // compartido no tape el último contenido.
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (analytics.warnings.lowData)
                          _LowDataWarning(
                            message: analytics.warnings.message,
                          ),

                        const SizedBox(height: 16),

                        _SummaryGrid(summary: analytics.summary),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Insights accionables',
                          subtitle:
                              'Recomendaciones generadas con reglas y datos reales.',
                        ),
                        const SizedBox(height: 12),
                        _InsightsList(insights: analytics.insights),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Perfil del público',
                          subtitle:
                              'Edad, ubicación e idioma de quienes reservan.',
                        ),
                        const SizedBox(height: 12),
                        _AudienceSection(audience: analytics.audience),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Conversión',
                          subtitle:
                              'Interés generado y conversión de favoritos a reservas.',
                        ),
                        const SizedBox(height: 12),
                        _ConversionCard(conversion: analytics.conversion),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Ocupación y fechas',
                          subtitle:
                              'Próximas salidas y uso real de los cupos.',
                        ),
                        const SizedBox(height: 12),
                        _UpcomingSchedulesCard(
                          schedules: analytics.schedules.upcoming,
                        ),
                        const SizedBox(height: 12),
                        _WeekdayOccupancyChart(
                          items: analytics.schedules.occupancyByWeekday,
                        ),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Mejor momento para publicar',
                          subtitle:
                              'Mapa simple por día y horario de reserva.',
                        ),
                        const SizedBox(height: 12),
                        _BookingHeatmapCard(
                          cells: analytics.schedules.bookingHeatmap,
                        ),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Demanda',
                          subtitle:
                              'Cuántos días antes suelen reservar los clientes.',
                        ),
                        const SizedBox(height: 12),
                        _LeadTimeCard(
                          leadTime: analytics.demand.bookingLeadTime,
                        ),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Experiencias rentables',
                          subtitle:
                              'Ranking por ingresos, reservas y ocupación.',
                        ),
                        const SizedBox(height: 12),
                        _ExperienceRankingCard(
                          items: analytics.experiences.topByRevenue,
                        ),

                        const SizedBox(height: 24),

                        _SectionTitle(
                          title: 'Clientes y lealtad',
                          subtitle:
                              'Clientes nuevos, recurrentes y potencial VIP.',
                        ),
                        const SizedBox(height: 12),
                        _LoyaltyCard(loyalty: analytics.loyalty),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      /// Navbar inferior real del afiliado.
      ///
      /// Este usa el widget compartido ProviderBottomNav.
      ///
      /// No estamos creando un navbar nuevo dentro de Analytics.
      /// Estamos reutilizando el navbar del flujo de afiliado.
      ///
      /// Analytics no es una pestaña principal en tu navbar actual.
      /// Por eso usamos currentIndex: -1 para no marcar ninguna opción activa.
      bottomNavigationBar: ProviderBottomNav(
        currentIndex: -1,
        onDashboard: () => _goToNamed(RouteNames.providerDashboard),
        onCatalog: () => _goToNamed(RouteNames.providerCatalog),
        onMessages: () => _goToNamed(RouteNames.providerMessages),
        onProfile: () => _goToNamed(RouteNames.providerProfile),
      ),
    );
  }
}

/// Colores locales de la pantalla.
///
/// Los definimos aquí para que esta pantalla compile sin depender todavía
/// de otros archivos visuales.
/// Luego, si quieres, podemos moverlos a AppColors.
class _AnalyticsColors {
  static const Color ultramar = AppColors.primaryBlue;

  /// Azul oscuro usado en fondos fuertes y tarjetas de recomendación.
  ///
  /// Lo dejamos como complemento visual del azul principal.
  static const Color ultramarDark = Color(0xFF071557);

  /// Azul suave para fondos de íconos, barras y elementos secundarios.
  static const Color ultramarSoft = Color(0xFFEFF6FF);

  /// Rojo de alerta/urgencia.
  static const Color vermilion = Color(0xFFE34234);

  /// Crema para warnings suaves.
  static const Color cream = Color(0xFFFFF8EE);

  /// Fondo general de la pantalla.
  static const Color background = Color(0xFFF8FAFC);

  /// Fondo de tarjetas.
  static const Color card = Colors.white;

  /// Texto principal.
  static const Color text = Color(0xFF111827);

  /// Texto secundario.
  static const Color muted = Color(0xFF6B7280);

  /// Bordes suaves.
  static const Color line = Color(0xFFE5E7EB);

  /// Verde para estados positivos.
  static const Color success = Color(0xFF17A673);

  /// Amarillo para advertencias.
  static const Color warning = Color(0xFFF7B731);
}

/// Header superior de la pantalla.
///
/// Contiene:
/// - nombre del proveedor
/// - período actual
/// - filtro por período
/// - filtro por experiencia
class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.analytics,
    required this.selectedPeriod,
    required this.selectedExperienceId,
    required this.onPeriodChanged,
    required this.onExperienceChanged,
  });

  final ProviderAnalyticsModel analytics;
  final String selectedPeriod;
  final int? selectedExperienceId;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<int?> onExperienceChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _AnalyticsColors.ultramar,
            _AnalyticsColors.ultramarDark,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LogoBadge(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  analytics.provider.businessName.isEmpty
                      ? 'Análisis del afiliado'
                      : analytics.provider.businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Análisis estadístico',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Datos reales para entender reservas, fechas, ocupación y oportunidades de marketing.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _PeriodSelector(
            selectedPeriod: selectedPeriod,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 12),
          _ExperienceSelector(
            experiences: analytics.availableExperiences,
            selectedExperienceId: selectedExperienceId,
            onChanged: onExperienceChanged,
          ),
        ],
      ),
    );
  }
}

/// Pequeño indicador visual de marca.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text(
        'A',
        style: TextStyle(
          color: _AnalyticsColors.ultramar,
          fontWeight: FontWeight.w900,
          fontSize: 19,
        ),
      ),
    );
  }
}

/// Selector horizontal de período.
///
/// Este widget reemplaza el ChoiceChip anterior porque en el header azul
/// los chips se estaban viendo como cuadros blancos sin texto claro.
///
/// Ahora usamos botones propios para controlar mejor:
/// - color seleccionado
/// - color no seleccionado
/// - bordes
/// - legibilidad
/// - tamaño
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final periods = <String, String>{
      '7d': '7 días',
      '30d': '30 días',
      '90d': '90 días',
      'year': 'Año',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.entries.map((entry) {
          final selected = selectedPeriod == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterPillButton(
              label: entry.value,
              isSelected: selected,
              onTap: () => onChanged(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Botón visual reutilizable para filtros del header.
///
/// Cuando está seleccionado:
/// - fondo blanco
/// - texto azul de AndanDO
///
/// Cuando NO está seleccionado:
/// - fondo azul oscuro/transparente
/// - texto blanco
///
/// Esto evita que los filtros se vean como cajas blancas vacías.
class _FilterPillButton extends StatelessWidget {
  const _FilterPillButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.12);

    final borderColor = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.24);

    final textColor = isSelected ? _AnalyticsColors.ultramar : Colors.white;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 76,
            minHeight: 38,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
/// Dropdown para filtrar por experiencia.
///
/// Incluye una opción null:
/// "Todas las experiencias".
/// Selector para filtrar por experiencia.
///
/// Antes se usaba DropdownButton directamente dentro del header.
/// Visualmente eso podía verse pesado o con poco contraste.
///
/// Ahora usamos PopupMenuButton para que el filtro se vea como una píldora
/// limpia y mantenga el estilo del header.
class _ExperienceSelector extends StatelessWidget {
  const _ExperienceSelector({
    required this.experiences,
    required this.selectedExperienceId,
    required this.onChanged,
  });

  final List<AnalyticsAvailableExperience> experiences;
  final int? selectedExperienceId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedExperience = _selectedExperience();
    final label = selectedExperience?.title ?? 'Todas las experiencias';

    return PopupMenuButton<int?>(
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return [
          const PopupMenuItem<int?>(
            value: null,
            child: Text(
              'Todas las experiencias',
              style: TextStyle(
                color: _AnalyticsColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...experiences.map(
            (experience) => PopupMenuItem<int?>(
              value: experience.id,
              child: Text(
                experience.title,
                style: const TextStyle(
                  color: _AnalyticsColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ];
      },
      child: Container(
        width: double.infinity,

        /// Container no tiene propiedad minHeight.
        ///
        /// Para definir una altura mínima usamos BoxConstraints.
        /// Esto significa:
        /// - el filtro medirá al menos 42 px de alto
        /// - pero puede crecer si el contenido lo necesita
        constraints: const BoxConstraints(
          minHeight: 42,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.explore_outlined,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Busca la experiencia seleccionada para mostrar su nombre en el filtro.
  ///
  /// Si selectedExperienceId es null, significa que el filtro está mostrando
  /// todas las experiencias.
  AnalyticsAvailableExperience? _selectedExperience() {
    if (selectedExperienceId == null) {
      return null;
    }

    for (final experience in experiences) {
      if (experience.id == selectedExperienceId) {
        return experience;
      }
    }

    return null;
  }
}
/// Aviso cuando hay pocos datos.
///
/// Esto evita que el afiliado interprete como definitivo un análisis basado
/// en pocas reservas.
class _LowDataWarning extends StatelessWidget {
  const _LowDataWarning({
    required this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      backgroundColor: _AnalyticsColors.cream,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: _AnalyticsColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ??
                  'Hay pocos datos todavía. Las métricas pueden cambiar cuando entren más reservas.',
              style: const TextStyle(
                color: _AnalyticsColors.text,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid de KPIs principales.
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.summary,
  });

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiData(
        label: 'Ingresos',
        value: summary.revenue.formatted,
        icon: Icons.payments_rounded,
      ),
      _KpiData(
        label: 'Reservas',
        value: summary.confirmedBookings.formatted,
        icon: Icons.confirmation_number_rounded,
      ),
      _KpiData(
        label: 'Personas',
        value: summary.confirmedGuests.formatted,
        icon: Icons.groups_rounded,
      ),
      _KpiData(
        label: 'Ocupación',
        value: summary.occupancyRate.formatted,
        icon: Icons.event_available_rounded,
      ),
      _KpiData(
        label: 'Favoritos',
        value: summary.favorites.formatted,
        icon: Icons.favorite_rounded,
      ),
      _KpiData(
        label: 'Cancelación',
        value: summary.cancellationRate.formatted,
        icon: Icons.cancel_rounded,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.42,
      ),
      itemBuilder: (context, index) {
        return _KpiCard(data: items[index]);
      },
    );
  }
}

/// Datos internos para una tarjeta KPI.
class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

/// Tarjeta individual de KPI.
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.data,
  });

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            color: _AnalyticsColors.ultramar,
            size: 22,
          ),
          const Spacer(),
          Text(
            data.label,
            style: const TextStyle(
              color: _AnalyticsColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AnalyticsColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título reutilizable de sección.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _AnalyticsColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _AnalyticsColors.muted,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Lista de insights generados por backend.
class _InsightsList extends StatelessWidget {
  const _InsightsList({
    required this.insights,
  });

  final List<AnalyticsInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _EmptyAnalyticsCard(
        title: 'Sin recomendaciones todavía',
        message:
            'Cuando haya más datos de reservas, aparecerán recomendaciones aquí.',
      );
    }

    return Column(
      children: insights
          .map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InsightCard(insight: insight),
            ),
          )
          .toList(),
    );
  }
}

/// Card visual de una recomendación.
class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
  });

  final AnalyticsInsight insight;

  @override
  Widget build(BuildContext context) {
    final isHigh = insight.priority == 'high';
    final color =
        isHigh ? _AnalyticsColors.vermilion : _AnalyticsColors.ultramar;

    return _AnalyticsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              insight.dataWarning
                  ? Icons.info_rounded
                  : Icons.auto_awesome_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    color: _AnalyticsColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  insight.description,
                  style: const TextStyle(
                    color: _AnalyticsColors.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: _AnalyticsColors.ultramarDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    insight.recommendation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de perfil de público.
class _AudienceSection extends StatelessWidget {
  const _AudienceSection({
    required this.audience,
  });

  final AnalyticsAudience audience;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AgeChartCard(items: audience.ageRanges),
        const SizedBox(height: 12),
        _RankingCard(
          title: 'Ciudades principales',
          emptyTitle: 'Sin ciudades todavía',
          emptyMessage:
              'Cuando entren reservas confirmadas, verás las ciudades que más compran.',
          items: audience.topCities,
        ),
        const SizedBox(height: 12),
        _RankingCard(
          title: 'Nacionalidades principales',
          emptyTitle: 'Sin nacionalidades todavía',
          emptyMessage:
              'Cuando los clientes completen su perfil, verás este análisis.',
          items: audience.topNationalities,
        ),
      ],
    );
  }
}

/// Gráfica de barras para rangos de edad.
class _AgeChartCard extends StatelessWidget {
  const _AgeChartCard({
    required this.items,
  });

  final List<AnalyticsRankingItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems =
        items.where((item) => item.label != 'Sin edad').toList();

    final hasData = visibleItems.any((item) => item.count > 0);

    if (!hasData) {
      return const _EmptyAnalyticsCard(
        title: 'Edad de clientes',
        message:
            'Todavía no hay reservas confirmadas con datos de edad para analizar.',
      );
    }

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Edad de clientes',
            subtitle: 'Rangos con mayor volumen de reservas.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= visibleItems.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            visibleItems[index].label,
                            style: const TextStyle(
                              color: _AnalyticsColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < visibleItems.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: visibleItems[i].count.toDouble(),
                          width: 18,
                          borderRadius: BorderRadius.circular(8),
                          color: _AnalyticsColors.ultramar,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de ranking con barras simples.
class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.title,
    required this.items,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String title;
  final List<AnalyticsRankingItem> items;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final validItems = items.where((item) => item.count > 0).toList();

    if (validItems.isEmpty) {
      return _EmptyAnalyticsCard(
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: title,
            subtitle: 'Top ${validItems.length} según reservas confirmadas.',
          ),
          const SizedBox(height: 14),
          ...validItems.map(
            (item) => _PercentageBar(item: item),
          ),
        ],
      ),
    );
  }
}

/// Barra porcentual simple.
class _PercentageBar extends StatelessWidget {
  const _PercentageBar({
    required this.item,
  });

  final AnalyticsRankingItem item;

  @override
  Widget build(BuildContext context) {
    final widthFactor = (item.percentage / 100).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: _AnalyticsColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${item.percentage}%',
                style: const TextStyle(
                  color: _AnalyticsColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: widthFactor,
              backgroundColor: _AnalyticsColors.ultramarSoft,
              color: _AnalyticsColors.ultramar,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de conversión.
class _ConversionCard extends StatelessWidget {
  const _ConversionCard({
    required this.conversion,
  });

  final AnalyticsConversion conversion;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Favoritos → reservas',
            subtitle:
                'Mide cuántos usuarios que guardan una experiencia terminan reservando.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Favoritos',
                  value: conversion.favoritesCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Convertidos',
                  value: conversion.convertedFavoritesCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Tasa',
                  value: '${conversion.favoritesToBookingsRate}%',
                ),
              ),
            ],
          ),
          if (conversion.viewsCount == null) ...[
            const SizedBox(height: 12),
            const Text(
              'Nota: el embudo completo de vistas no está disponible porque todavía no usamos tabla de eventos.',
              style: TextStyle(
                color: _AnalyticsColors.muted,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card de próximas salidas.
class _UpcomingSchedulesCard extends StatelessWidget {
  const _UpcomingSchedulesCard({
    required this.schedules,
  });

  final List<AnalyticsUpcomingSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const _EmptyAnalyticsCard(
        title: 'Sin próximas fechas',
        message:
            'Cuando crees salidas activas, aquí verás su ocupación y cupos disponibles.',
      );
    }

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Próximas salidas',
            subtitle: 'Fechas con ocupación y cupos disponibles.',
          ),
          const SizedBox(height: 14),
          ...schedules.map(
            (schedule) => _UpcomingScheduleRow(schedule: schedule),
          ),
        ],
      ),
    );
  }
}

/// Fila visual de una fecha.
class _UpcomingScheduleRow extends StatelessWidget {
  const _UpcomingScheduleRow({
    required this.schedule,
  });

  final AnalyticsUpcomingSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final startsAt = DateTime.tryParse(schedule.startsAt);
    final dateLabel = startsAt == null
        ? 'Fecha'
        : DateFormat('d MMM', 'es').format(startsAt.toLocal());

    final progress = (schedule.occupancyRate / 100).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            decoration: BoxDecoration(
              color: _AnalyticsColors.ultramarSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dateLabel.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AnalyticsColors.ultramar,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.experienceTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AnalyticsColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: _AnalyticsColors.ultramarSoft,
                    color: schedule.needsPromotion
                        ? _AnalyticsColors.vermilion
                        : _AnalyticsColors.success,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${schedule.booked} de ${schedule.capacity} cupos vendidos',
                  style: const TextStyle(
                    color: _AnalyticsColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${schedule.occupancyRate}%',
            style: TextStyle(
              color: schedule.needsPromotion
                  ? _AnalyticsColors.vermilion
                  : _AnalyticsColors.success,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfica de ocupación por día de semana.
class _WeekdayOccupancyChart extends StatelessWidget {
  const _WeekdayOccupancyChart({
    required this.items,
  });

  final List<AnalyticsWeekdayOccupancy> items;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Ocupación por día',
            subtitle: 'Ayuda a decidir qué días abrir más salidas.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 100,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= items.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            items[index].label,
                            style: const TextStyle(
                              color: _AnalyticsColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < items.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: items[i].occupancyRate.toDouble(),
                          width: 18,
                          borderRadius: BorderRadius.circular(8),
                          color: _AnalyticsColors.ultramar,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Heatmap custom.
///
/// No usamos librería aquí porque es una cuadrícula simple.
/// Cada celda usa intensidad 0-5 enviada por backend.
class _BookingHeatmapCard extends StatelessWidget {
  const _BookingHeatmapCard({
    required this.cells,
  });

  final List<AnalyticsHeatmapCell> cells;

  @override
  Widget build(BuildContext context) {
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final blocks = ['AM', 'PM', 'NOC'];

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Día y horario',
            subtitle: 'Mientras más intenso el color, más reservas.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 42),
              ...days.map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: _AnalyticsColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...blocks.map(
            (block) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      block,
                      style: const TextStyle(
                        color: _AnalyticsColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ...days.map(
                    (day) {
                      final cell = cells.firstWhere(
                        (item) =>
                            item.dayLabel == day && item.blockLabel == block,
                        orElse: () => AnalyticsHeatmapCell(
                          day: '',
                          dayLabel: day,
                          block: '',
                          blockLabel: block,
                          count: 0,
                          intensity: 0,
                        ),
                      );

                      return Expanded(
                        child: Container(
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _heatmapColor(cell.intensity),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convierte intensidad 0-5 en color visual.
  Color _heatmapColor(int intensity) {
    if (intensity <= 0) {
      return const Color(0xFFEEF1FB);
    }

    if (intensity == 1) {
      return const Color(0xFFDDE4FF);
    }

    if (intensity == 2) {
      return const Color(0xFFAEBBFF);
    }

    if (intensity == 3) {
      return const Color(0xFF5E78FF);
    }

    if (intensity == 4) {
      return _AnalyticsColors.ultramar;
    }

    return _AnalyticsColors.vermilion;
  }
}

/// Card de anticipación de reserva.
class _LeadTimeCard extends StatelessWidget {
  const _LeadTimeCard({
    required this.leadTime,
  });

  final AnalyticsBookingLeadTime leadTime;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Anticipación promedio',
            subtitle:
                'Tus clientes reservan en promedio ${leadTime.averageDays} días antes.',
          ),
          const SizedBox(height: 14),
          ...leadTime.ranges.map(
            (item) => _PercentageBar(item: item),
          ),
        ],
      ),
    );
  }
}

/// Ranking de experiencias.
class _ExperienceRankingCard extends StatelessWidget {
  const _ExperienceRankingCard({
    required this.items,
  });

  final List<AnalyticsExperiencePerformance> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyAnalyticsCard(
        title: 'Sin experiencias para mostrar',
        message: 'Cuando tengas experiencias, aparecerán en este ranking.',
      );
    }

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Top por ingresos',
            subtitle: 'Ordenado por ganancias del proveedor.',
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map(
                (entry) => _ExperienceRankingRow(
                  index: entry.key + 1,
                  item: entry.value,
                ),
              ),
        ],
      ),
    );
  }
}

/// Fila del ranking de experiencias.
class _ExperienceRankingRow extends StatelessWidget {
  const _ExperienceRankingRow({
    required this.index,
    required this.item,
  });

  final int index;
  final AnalyticsExperiencePerformance item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _AnalyticsColors.ultramarSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              index.toString(),
              style: const TextStyle(
                color: _AnalyticsColors.ultramar,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AnalyticsColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.guestsCount} personas · ${item.occupancyRate}% ocupación',
                  style: const TextStyle(
                    color: _AnalyticsColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.revenueFormatted,
            style: const TextStyle(
              color: _AnalyticsColors.ultramarDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de clientes y lealtad.
class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({
    required this.loyalty,
  });

  final AnalyticsLoyalty loyalty;

  @override
  Widget build(BuildContext context) {
    final hasPieData =
        loyalty.newCustomers > 0 || loyalty.recurrentCustomers > 0;

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Clientes',
            subtitle: 'Compara nuevos clientes contra clientes recurrentes.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Nuevos',
                  value: '${loyalty.newCustomersRate}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'Recurrentes',
                  value: '${loyalty.recurrentCustomersRate}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: 'VIP',
                  value: loyalty.vipCustomersCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasPieData)
            SizedBox(
              height: 130,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 34,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: loyalty.newCustomers.toDouble(),
                      title: 'Nuevos',
                      radius: 42,
                      color: _AnalyticsColors.ultramar,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    PieChartSectionData(
                      value: loyalty.recurrentCustomers.toDouble(),
                      title: 'Recurrentes',
                      radius: 42,
                      color: _AnalyticsColors.vermilion,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'Cuando tengas reservas confirmadas, aquí verás la proporción de clientes nuevos y recurrentes.',
              style: TextStyle(
                color: _AnalyticsColors.muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Métrica pequeña reutilizable.
class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _AnalyticsColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AnalyticsColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _AnalyticsColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AnalyticsColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header pequeño para cards internas.
class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _AnalyticsColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _AnalyticsColors.muted,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Card base reutilizable de analytics.
class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = _AnalyticsColors.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AnalyticsColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Empty state reutilizable para secciones sin data.
class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _AnalyticsColors.ultramarSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: _AnalyticsColors.ultramar,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CardHeader(
              title: title,
              subtitle: message,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de carga.
class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _AnalyticsColors.ultramar,
      ),
    );
  }
}

/// Estado de error.
class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _AnalyticsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _AnalyticsColors.vermilion,
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudo cargar el análisis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AnalyticsColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _AnalyticsColors.muted,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AnalyticsColors.ultramar,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}