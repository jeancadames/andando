import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../explore/data/models/customer_experience_model.dart';
import '../../../explore/presentation/controllers/explore_controller.dart';
import '../../../explore/presentation/screens/experience_detail_screen.dart';
import '../widgets/favorite_experience_card.dart';

class CustomerFavoritesScreen extends StatefulWidget {
  const CustomerFavoritesScreen({super.key});

  @override
  State<CustomerFavoritesScreen> createState() =>
      _CustomerFavoritesScreenState();
}

class _CustomerFavoritesScreenState extends State<CustomerFavoritesScreen> {
  final ExploreController _controller = ExploreController();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CustomerExperienceModel> get _favoriteExperiences {
    return _controller.experiences.where((experience) {
      return _controller.favoriteExperienceIds.contains(experience.id);
    }).toList();
  }

  Future<void> _openExperienceDetail(
    CustomerExperienceModel experience,
  ) async {
    final currentFavoriteState = _controller.isFavorite(experience.id);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperienceDetailScreen(
          experience: experience,
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
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final favorites = _favoriteExperiences;
        final favoriteCount = favorites.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _controller.loadExperiences,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _FavoritesHeader(
                      favoriteCount: favoriteCount,
                    ),
                  ),

                  if (_controller.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_controller.errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FavoritesErrorState(
                        message: _controller.errorMessage!,
                        onRetry: _controller.loadExperiences,
                      ),
                    )
                  else if (favorites.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FavoritesEmptyState(
                        onExploreTap: () {
                          context.go('/client/explore');
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                      sliver: SliverList.separated(
                        itemCount: favorites.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final experience = favorites[index];

                          return FavoriteExperienceCard(
                            experience: experience,
                            onTap: () => _openExperienceDetail(experience),
                            onFavoriteTap: () {
                              _controller.toggleFavorite(experience.id);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const _FavoritesBottomNavigation(),
        );
      },
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  final int favoriteCount;

  const _FavoritesHeader({
    required this.favoriteCount,
  });

  @override
  Widget build(BuildContext context) {
    final counterText = favoriteCount == 1
        ? '1 experiencia guardada'
        : '$favoriteCount experiencias guardadas';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tus favoritos',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
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
                  Icons.favorite_rounded,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Experiencias que guardaste para después',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              counterText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  final VoidCallback onExploreTap;

  const _FavoritesEmptyState({
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEEF2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 44,
                color: Color(0xFFE11D48),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aún no tienes favoritos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Guarda experiencias desde Explorar y aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: onExploreTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Explorar experiencias',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FavoritesErrorState({
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
              'No pudimos cargar tus favoritos',
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

class _FavoritesBottomNavigation extends StatelessWidget {
  const _FavoritesBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 2,
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go('/client/explore');
        }

        if (index == 1) {
          context.go('/client/bookings');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Explorar',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Reservas',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: 'Favoritos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}