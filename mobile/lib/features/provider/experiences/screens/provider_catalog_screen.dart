import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_controller.dart';
import '../models/provider_experience.dart';
import '../services/provider_experience_service.dart';
import 'create_experience_screen.dart';
import 'experience_calendar_screen.dart';

class ProviderCatalogScreen extends StatefulWidget {
  const ProviderCatalogScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<ProviderCatalogScreen> createState() => _ProviderCatalogScreenState();
}

class _ProviderCatalogScreenState extends State<ProviderCatalogScreen> {
  final ProviderExperienceService _service = ProviderExperienceService();

  String _activeTab = 'published';
  bool _isLoading = true;
  String? _error;

  List<ProviderExperience> _publishedExperiences = [];
  List<ProviderExperience> _draftExperiences = [];

  List<ProviderExperience> get _displayExperiences {
    if (_activeTab == 'draft') {
      return _draftExperiences;
    }

    return _publishedExperiences;
  }

  @override
  void initState() {
    super.initState();
    _loadExperiences();
  }

  Future<void> _loadExperiences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.listExperiences(
          token: widget.authController.token,
          status: 'published',
        ),
        _service.listExperiences(
          token: widget.authController.token,
          status: 'draft',
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _publishedExperiences = results[0];
        _draftExperiences = results[1];
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteExperience(ProviderExperience experience) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar experiencia'),
          content: Text(
            '¿Seguro que deseas eliminar "${experience.title}"? '
            'No se borrará físicamente de la base de datos, solo dejará de mostrarse.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _service.deleteExperience(
        id: experience.id,
        token: widget.authController.token,
      );

      await _loadExperiences();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    }
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExperienceScreen(
          authController: widget.authController,
        ),
      ),
    ).then((_) => _loadExperiences());
  }

  void _openEdit(ProviderExperience experience) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExperienceScreen(
          authController: widget.authController,
          experienceId: experience.id,
        ),
      ),
    ).then((_) => _loadExperiences());
  }

  void _openCalendar(ProviderExperience experience) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExperienceCalendarScreen(
          authController: widget.authController,
          experienceId: experience.id,
          experienceTitle: experience.title,
        ),
      ),
    ).then((_) => _loadExperiences());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
      ),
    );
  }

  void _goToDashboard() {
    context.go('/provider/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CatalogColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: _goToDashboard,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: _CatalogColors.primary,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Mi Catálogo',
          style: TextStyle(
            color: _CatalogColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                onTap: _openCreate,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: _CatalogColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 23,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: _Tabs(
              activeTab: _activeTab,
              publishedCount: _publishedExperiences.length,
              draftCount: _draftExperiences.length,
              onChanged: (value) {
                setState(() {
                  _activeTab = value;
                });
              },
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: _CatalogColors.border,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadExperiences,
              color: _CatalogColors.primary,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ProviderBottomNav(
        currentIndex: 1,
        onDashboard: () => context.go('/provider/dashboard'),
        onCatalog: () {},
        onMessages: () => context.go('/provider/messages'),
        onProfile: () => context.go('/provider/profile'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _CatalogColors.primary,
        ),
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.error_outline,
            size: 56,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _error!.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadExperiences,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_displayExperiences.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.card_travel,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _activeTab == 'published'
                ? 'No tienes experiencias activas'
                : 'No tienes borradores',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _CatalogColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _activeTab == 'published'
                ? 'Publica tu primera experiencia para empezar a recibir reservas.'
                : 'Guarda borradores mientras completas tus experiencias.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _CatalogColors.mutedText,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _openCreate,
            style: FilledButton.styleFrom(
              backgroundColor: _CatalogColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear experiencia'),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 96),
      itemCount: _displayExperiences.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final experience = _displayExperiences[index];

        return _ExperienceCard(
          experience: experience,
          onCalendar: () => _openCalendar(experience),
          onEdit: () => _openEdit(experience),
          onDelete: () => _deleteExperience(experience),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  final String activeTab;
  final int publishedCount;
  final int draftCount;
  final ValueChanged<String> onChanged;

  const _Tabs({
    required this.activeTab,
    required this.publishedCount,
    required this.draftCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Activas ($publishedCount)',
            selected: activeTab == 'published',
            onTap: () => onChanged('published'),
          ),
          _TabButton(
            label: 'Borradores ($draftCount)',
            selected: activeTab == 'draft',
            onTap: () => onChanged('draft'),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? _CatalogColors.primary
                  : _CatalogColors.mutedText,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final ProviderExperience experience;
  final VoidCallback onCalendar;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExperienceCard({
    required this.experience,
    required this.onCalendar,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = experience.status == 'draft';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _CatalogColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ExperienceHeader(
                    experience: experience,
                    isDraft: isDraft,
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    color: _CatalogColors.mutedText,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
            if (!isDraft) ...[
              const SizedBox(height: 16),
              _MetricsGrid(experience: experience),
            ],
            const SizedBox(height: 16),
            _CardActions(
              isDraft: isDraft,
              onCalendar: onCalendar,
              onEdit: onEdit,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRevenue(double revenue) {
    if (revenue >= 1000) {
      return 'RD\$${(revenue / 1000).toStringAsFixed(0)}k';
    }

    return 'RD\$${revenue.toStringAsFixed(0)}';
  }
}

class _CardActions extends StatelessWidget {
  final bool isDraft;
  final VoidCallback onCalendar;
  final VoidCallback onEdit;

  const _CardActions({
    required this.isDraft,
    required this.onCalendar,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: _CatalogActionButton(
              label: isDraft ? 'Configurar Fechas' : 'Ver Calendario',
              onTap: onCalendar,
              backgroundColor:
                  isDraft ? Colors.white : _CatalogColors.primary,
              borderColor: _CatalogColors.primary,
              textColor:
                  isDraft ? _CatalogColors.primary : Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CatalogActionButton(
              label: 'Editar',
              onTap: onEdit,
              backgroundColor: Colors.white,
              borderColor: _CatalogColors.borderDark,
              textColor: _CatalogColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _CatalogActionButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 1.3,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final ProviderExperience experience;

  const _MetricsGrid({
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.65,
      children: [
        _MetricBox(
          label: 'Reservas',
          value: experience.bookingsCount.toString(),
          icon: Icons.groups_2_outlined,
          background: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF1D4ED8),
          valueColor: const Color(0xFF1D4ED8),
        ),
        _MetricBox(
          label: 'Ingresos',
          value: _formatRevenue(experience.revenue),
          icon: Icons.trending_up,
          background: const Color(0xFFEFFBF3),
          iconColor: const Color(0xFF16A34A),
          valueColor: const Color(0xFF16A34A),
        ),
        _MetricBox(
          label: 'Vistas',
          value: experience.views.toString(),
          icon: Icons.visibility_outlined,
          background: const Color(0xFFFAF5FF),
          iconColor: const Color(0xFF9333EA),
          valueColor: const Color(0xFF9333EA),
        ),
        _MetricBox(
          label: 'Rating',
          value: experience.rating.toStringAsFixed(1),
          icon: Icons.star,
          background: const Color(0xFFFFFBEA),
          iconColor: const Color(0xFFEAB308),
          valueColor: const Color(0xFFA16207),
        ),
      ],
    );
  }

  static String _formatRevenue(double revenue) {
    if (revenue >= 1000) {
      return 'RD\$${(revenue / 1000).toStringAsFixed(0)}k';
    }

    return 'RD\$${revenue.toStringAsFixed(0)}';
  }
}

class _ExperienceHeader extends StatelessWidget {
  final ProviderExperience experience;
  final bool isDraft;

  const _ExperienceHeader({
    required this.experience,
    required this.isDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          experience.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _CatalogColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        if (isDraft)
          const Row(
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 15,
                color: Color(0xFFD97706),
              ),
              SizedBox(width: 6),
              Text(
                'No visible para clientes',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 15,
                color: _CatalogColors.mutedText,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: _CatalogColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: experience.nextAvailable == null
                            ? 'Sin próxima fecha'
                            : 'Próxima: ${_formatDate(experience.nextAvailable!)}',
                      ),
                      TextSpan(
                        text: '  •  ${experience.schedulesCount} fechas',
                        style: const TextStyle(
                          color: _CatalogColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    return DateFormat('dd/M/yyyy').format(date);
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final Color valueColor;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1,
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

class _ProviderBottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onDashboard;
  final VoidCallback onCatalog;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  const _ProviderBottomNav({
    required this.currentIndex,
    required this.onDashboard,
    required this.onCatalog,
    required this.onMessages,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _CatalogColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _BottomNavItem(
                label: 'Dashboard',
                icon: Icons.trending_up,
                isActive: currentIndex == 0,
                onTap: onDashboard,
              ),
              _BottomNavItem(
                label: 'Catálogo',
                icon: Icons.calendar_month_outlined,
                isActive: currentIndex == 1,
                onTap: onCatalog,
              ),
              _BottomNavItem(
                label: 'Mensajes',
                icon: Icons.chat_bubble_outline,
                isActive: currentIndex == 2,
                showDot: true,
                onTap: onMessages,
              ),
              _BottomNavItem(
                label: 'Perfil',
                icon: Icons.person_outline,
                isActive: currentIndex == 3,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? _CatalogColors.primary : _CatalogColors.mutedText;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showDot)
              Positioned(
                top: 13,
                right: 28,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _CatalogColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatalogColors {
  static const Color primary = Color(0xFF003A78);
  static const Color background = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);
}