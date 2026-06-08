import 'dart:async';

import '../../../shared/widgets/customer_bottom_navigation.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../../../core/router/route_names.dart';
import '../controllers/explore_controller.dart';
import '../../data/models/customer_experience_model.dart';
import 'experience_detail_screen.dart';

import '../../../../auth/application/auth_controller.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ExploreController _controller = ExploreController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isLoggedAsCustomer {
    final isAuthenticated = widget.authController.isAuthenticated;
    final userType = widget.authController.userType?.trim().toLowerCase() ?? '';
    final token = widget.authController.token?.trim() ?? '';

    return isAuthenticated &&
        token.isNotEmpty &&
        (userType == 'customer' || userType == 'client' || userType == 'user');
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _controller.search(value);
    });
  }

  Future<void> _showFavoriteLoginDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Guarda tus experiencias favoritas',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          content: const Text(
            'Para guardar esta experiencia en favoritos necesitas crear una cuenta o iniciar sesión como cliente.',
            style: TextStyle(
              height: 1.4,
              color: Color(0xFF475569),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.goNamed(RouteNames.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B73),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Crear cuenta'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleFavoriteTap(CustomerExperienceModel experience) async {
    if (!_isLoggedAsCustomer) {
      await _showFavoriteLoginDialog();
      return;
    }

    _controller.toggleFavorite(experience.id);
  }

  Future<void> _openExperienceDetail(
    BuildContext context,
    CustomerExperienceModel experience,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final detailExperience = await _controller.dataSource.getExperienceDetail(
        experienceId: experience.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      final currentFavoriteState = _controller.isFavorite(experience.id);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExperienceDetailScreen(
            experience: detailExperience,
            authController: widget.authController,
            initialIsFavorite: currentFavoriteState,
            onFavoriteChanged: (isFavorite) {
              final currentState = _controller.isFavorite(experience.id);

              if (currentState != isFavorite) {
                _controller.toggleFavorite(experience.id);
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  String _formatFilterDate(DateTime date) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month]} '
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _controller.loadExperiences,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryList(
                          controller: _controller,
                        ),
                        if (_controller.selectedDate != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              4,
                              20,
                              12,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                _controller.clearSelectedDate();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3FF),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF003B73),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                      color: Color(0xFF003B73),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatFilterDate(
                                        _controller.selectedDate!,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF003B73),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Color(0xFF003B73),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_controller.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_controller.errorMessage != null)
                    SliverFillRemaining(
                      child: _ErrorState(
                        message: _controller.errorMessage!,
                        onRetry: _controller.loadExperiences,
                      ),
                    )
                  else if (_controller.experiences.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(
                        onClearFilters: _controller.clearFilters,
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: _ExperienceCarouselSection(
                        title: 'Actividades populares',
                        subtitle: 'Experiencias recomendadas para ti',
                        experiences: _controller.popularExperiences,
                        controller: _controller,
                        onOpenExperience: (experience) {
                          _openExperienceDetail(context, experience);
                        },
                        onFavoriteTap: _handleFavoriteTap,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ExperienceCarouselSection(
                        title: 'Actividades recomendadas',
                        subtitle: 'Basadas en tus favoritos',
                        experiences: _controller.recommendedExperiences,
                        controller: _controller,
                        onOpenExperience: (experience) {
                          _openExperienceDetail(context, experience);
                        },
                        onFavoriteTap: _handleFavoriteTap,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ExperienceCarouselSection(
                        title: 'Actividades cercanas a ti',
                        subtitle: 'Opciones disponibles cerca de tu ubicación',
                        experiences: _controller.nearbyExperiences,
                        controller: _controller,
                        onOpenExperience: (experience) {
                          _openExperienceDetail(context, experience);
                        },
                        onFavoriteTap: _handleFavoriteTap,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: CustomerBottomNavigation(
            currentItem: CustomerBottomNavItem.explore,
            authController: widget.authController,
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _Header({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Explorar ofertas',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Encuentra experiencias únicas cerca de ti',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar experiencias',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final ExploreController controller;

  const _CategoryList({
    required this.controller,
  });

  Future<void> _openDatePicker(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (selected != null) {
      await controller.selectDate(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        12,
      ),
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  final isSelected = category == controller.selectedCategory;

                  return GestureDetector(
                    onTap: () => controller.selectCategory(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF111827)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(
                    const Duration(days: 365),
                  ),
                );

                if (selected != null) {
                  await controller.selectDate(selected);
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: controller.selectedDate != null
                      ? const Color(0xFF003B73)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: controller.selectedDate != null
                      ? Colors.white
                      : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFilterBar extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onSelectDate;
  final VoidCallback onClearDate;

  const _DateFilterBar({
    required this.selectedDate,
    required this.onSelectDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    final label = selectedDate == null
        ? 'Filtrar por fecha'
        : 'Fecha: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSelectDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(label),
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(width: 10),
            IconButton(
              onPressed: onClearDate,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExperienceCarouselSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<CustomerExperienceModel> experiences;
  final ExploreController controller;
  final ValueChanged<CustomerExperienceModel> onOpenExperience;
  final ValueChanged<CustomerExperienceModel> onFavoriteTap;

  const _ExperienceCarouselSection({
    required this.title,
    required this.subtitle,
    required this.experiences,
    required this.controller,
    required this.onOpenExperience,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (experiences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: title,
          subtitle: subtitle,
        ),
        SizedBox(
          height: 350,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: experiences.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final experience = experiences[index];

              return SizedBox(
                width: 260,
                child: _ExperienceCard(
                  experience: experience,
                  isFavorite: controller.isFavorite(experience.id),
                  onFavoriteTap: () => onFavoriteTap(experience),
                  onTap: () => onOpenExperience(experience),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final CustomerExperienceModel experience;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _ExperienceCard({
    required this.experience,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = experience.coverPhotoUrl != null &&
        experience.coverPhotoUrl!.trim().isNotEmpty;

    debugPrint('EXPERIENCIA: ${experience.title}');
    debugPrint('COVER PHOTO URL: ${experience.coverPhotoUrl}');
    debugPrint('HAS IMAGE: $hasImage');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 330,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 155,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasImage
                        ? Image.network(
                            experience.coverPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('ERROR IMAGEN EXPLORE: $error');
                              debugPrint(
                                'URL IMAGEN EXPLORE: ${experience.coverPhotoUrl}',
                              );

                              return const _ImagePlaceholder();
                            },
                          )
                        : const _ImagePlaceholder(),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 21,
                          color: isFavorite
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  if (experience.category != null)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          experience.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            experience.displayLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            experience.formattedNextAvailableDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            experience.displayDuration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          experience.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          experience.formattedPrice,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              size: 54,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 14),
            const Text(
              'No hay experiencias disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prueba cambiando la búsqueda o la categoría seleccionada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onClearFilters,
              child: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            const Text(
              'No pudimos cargar las experiencias',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}