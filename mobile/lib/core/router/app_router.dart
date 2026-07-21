import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';

import '../../features/customer/profile/presentation/screens/customer_terms_conditions_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_help_center_screen.dart';
import '../../features/customer/claims/presentation/screens/create_claim_screen.dart';
import '../../features/customer/reviews/presentation/screens/experience_reviews_screen.dart';
import '../../features/customer/booking/data/models/customer_booking_model.dart';
import '../../features/customer/reviews/presentation/screens/create_review_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_profile_screen.dart';
import '../../features/customer/profile/presentation/screens/edit_customer_profile_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_profile_settings_screen.dart';
import '../../features/customer/booking/presentation/screens/customer_bookings_screen.dart';
import '../../features/customer/favorites/presentation/screens/customer_favorites_screen.dart';
import '../../features/customer/chat/presentation/screens/customer_chat_list_screen.dart';
import '../../features/customer/chat/presentation/screens/customer_chat_screen.dart';

import '../../features/chat/data/models/chat_conversation_model.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';

import '../../features/customer/auth/presentation/screens/customer_register_screen.dart';
import '../../features/customer/explore/data/models/customer_experience_model.dart';
import '../../features/customer/explore/presentation/controllers/explore_controller.dart';
import '../../features/customer/explore/presentation/screens/experience_detail_screen.dart';
import '../../features/customer/explore/presentation/screens/explore_screen.dart';

import '../../features/provider/dashboard/screens/provider_dashboard_screen.dart';
import '../../features/provider/experiences/screens/add_schedule_screen.dart';
import '../../features/provider/experiences/screens/create_experience_screen.dart';
import '../../features/provider/experiences/screens/experience_calendar_screen.dart';
import '../../features/provider/experiences/screens/provider_catalog_screen.dart';
import '../../features/provider/experiences/screens/provider_experience_reviews_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_register_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_verification_pending_screen.dart';
import '../../features/provider/profile/screens/provider_profile_screen.dart';
import '../../features/provider/profile/screens/provider_settings_screen.dart';
import '../../features/provider/bookings/screens/provider_bookings_screen.dart';
import '../../features/provider/analytics/screens/provider_analytics_screen.dart';
import '../../features/provider/chat/presentation/screens/provider_chat_list_screen.dart';
import '../../features/provider/chat/presentation/screens/provider_chat_screen.dart';

import '../../features/payments/presentation/screens/customer_payment_methods_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_location_settings_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_notification_settings_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_privacy_security_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_change_password_screen.dart';

import 'route_names.dart';

class AppRouter {
  AppRouter({
    required AuthController authController,
  }) : _authController = authController;

  final AuthController _authController;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authController,
    redirect: _redirect,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) {
          return LoginScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) {
          return const ForgotPasswordScreen();
        },
      ),

      GoRoute(
        path: '/reset-password',
        name: RouteNames.resetPassword,
        builder: (context, state) {
          return ResetPasswordScreen(
            email: state.uri.queryParameters['email'] ?? '',
            token: state.uri.queryParameters['token'] ?? '',
          );
        },
      ),

      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) {
          return CustomerRegisterScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/client/explore',
        name: RouteNames.clientExplore,
        builder: (context, state) {
          return ExploreScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/client/bookings',
        name: RouteNames.clientBookings,
        builder: (context, state) {
          return CustomerBookingsScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/client/bookings/:bookingId/review',
        name: RouteNames.createReview,
        builder: (context, state) {
          final bookingId = int.tryParse(
            state.pathParameters['bookingId'] ?? '',
          );

          final booking = state.extra as CustomerBookingModel?;

          if (bookingId == null || booking == null) {
            return const _RouteErrorPlaceholder(
              message: 'No pudimos abrir la pantalla de reseña.',
            );
          }

          return CreateReviewScreen(
            booking: booking,
          );
        },
      ),

      GoRoute(
        path: '/client/bookings/:bookingId/claim',
        name: 'createClaim',
        builder: (context, state) {
          final bookingId = int.tryParse(
            state.pathParameters['bookingId'] ?? '',
          );

          final booking = state.extra as CustomerBookingModel?;

          if (bookingId == null || booking == null) {
            return const _RouteErrorPlaceholder(
              message: 'No pudimos abrir la pantalla de reclamo.',
            );
          }

          return CreateClaimScreen(
            booking: booking,
          );
        },
      ),

      GoRoute(
        path: '/client/favorites',
        name: RouteNames.clientFavorites,
        builder: (context, state) {
          return CustomerFavoritesScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/customer/profile',
        name: RouteNames.customerProfile,
        builder: (context, state) {
          return CustomerProfileScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/customer/profile/edit',
        name: RouteNames.customerProfileEdit,
        builder: (context, state) {
          return const EditCustomerProfileScreen();
        },
      ),
      GoRoute(
        path: '/customer/profile/settings',
        name: RouteNames.customerProfileSettings,
        builder: (context, state) {
          return CustomerProfileSettingsScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/customer/profile/location',
        name: 'customerLocationSettings',
        builder: (context, state) {
          return const CustomerLocationSettingsScreen();
        },
      ),

      GoRoute(
        path: '/customer/profile/notifications',
        name: 'customerNotificationSettings',
        builder: (context, state) {
          return CustomerNotificationSettingsScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/customer/profile/privacy-security',
        name: 'customerPrivacySecurity',
        builder: (context, state) {
          return const CustomerPrivacySecurityScreen();
        },
      ),

      GoRoute(
        path: '/customer/profile/change-password',
        name: 'customerChangePassword',
        builder: (context, state) {
          return CustomerChangePasswordScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/customer/profile/payment-methods',
        name: 'customerPaymentMethods',
        builder: (context, state) {
          return const CustomerPaymentMethodsScreen();
        },
      ),
      GoRoute(
        path: '/customer/dashboard',
        name: RouteNames.customerDashboard,
        builder: (context, state) {
          return ExploreScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/client/messages',
        name: RouteNames.clientMessages,
        builder: (context, state) {
          return CustomerChatListScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/client/messages/:conversationId',
        name: RouteNames.clientChatDetail,
        builder: (context, state) {
          final conversationId = int.tryParse(
            state.pathParameters['conversationId'] ?? '',
          );

          final initialConversation = state.extra is ChatConversationModel
              ? state.extra as ChatConversationModel
              : null;

          if (conversationId == null) {
            return const _RouteErrorPlaceholder(
              message: 'No pudimos abrir esta conversación.',
            );
          }

          return CustomerChatScreen(
            authController: _authController,
            conversationId: conversationId,
            initialConversation: initialConversation,
          );
        },
      ),
      GoRoute(
        path: '/experiences/:id',
        name: RouteNames.experienceDetail,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          final openBookingReview =
              state.uri.queryParameters['openBookingReview'] == '1';

          final initialScheduleId = int.tryParse(
            state.uri.queryParameters['scheduleId'] ?? '',
          );

          final initialTravelers = int.tryParse(
            state.uri.queryParameters['travelers'] ?? '',
          );

          return _PublicExperienceDetailLoader(
            experienceId: experienceId,
            authController: _authController,
            openBookingReview: openBookingReview,
            initialScheduleId: initialScheduleId,
            initialTravelers: initialTravelers,
          );
        },
      ),
      GoRoute(
        path: '/experiences/:experienceId/reviews',
        name: RouteNames.experienceReviews,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['experienceId'] ?? '',
          );

          final extra = state.extra as Map<String, dynamic>?;

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'No pudimos abrir las reseñas.',
            );
          }

          return ExperienceReviewsScreen(
            experienceId: experienceId,
            averageRating: (extra?['averageRating'] as num?)?.toDouble() ?? 0,
            totalReviews: (extra?['totalReviews'] as int?) ?? 0,
          );
        },
      ),

      GoRoute(
        path: '/affiliate/register',
        name: RouteNames.affiliateRegister,
        builder: (context, state) {
          return ProviderRegisterScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/register',
        name: RouteNames.providerRegister,
        builder: (context, state) {
          return ProviderRegisterScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/login',
        name: RouteNames.providerLogin,
        builder: (context, state) {
          return LoginScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/verification-pending',
        name: RouteNames.providerVerificationPending,
        builder: (context, state) {
          return ProviderVerificationPendingScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/dashboard',
        name: RouteNames.providerDashboard,
        builder: (context, state) {
          return ProviderDashboardScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/catalog',
        name: RouteNames.providerCatalog,
        builder: (context, state) {
          return ProviderCatalogScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/create-experience',
        name: RouteNames.providerCreateExperience,
        builder: (context, state) {
          return CreateExperienceScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/edit-experience/:id',
        name: RouteNames.providerEditExperience,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return CreateExperienceScreen(
            authController: _authController,
            experienceId: experienceId,
          );
        },
      ),
      GoRoute(
        path: '/provider/experience-calendar/:id/add-schedule',
        name: RouteNames.providerAddSchedule,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          final title = state.uri.queryParameters['title'] ?? 'Experiencia';

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return AddScheduleScreen(
            authController: _authController,
            experienceId: experienceId,
            experienceTitle: title,
          );
        },
      ),
      GoRoute(
        path: '/provider/experience-calendar/:id',
        name: RouteNames.providerExperienceCalendar,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          final title = state.uri.queryParameters['title'] ?? 'Experiencia';

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return ExperienceCalendarScreen(
            authController: _authController,
            experienceId: experienceId,
            experienceTitle: title,
          );
        },
      ),
      GoRoute(
        path: '/provider/experiences/:id/reviews',
        name: RouteNames.providerExperienceReviews,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          final title = state.uri.queryParameters['title'] ?? 'Experiencia';

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return ProviderExperienceReviewsScreen(
            authController: _authController,
            experienceId: experienceId,
            initialTitle: title,
          );
        },
      ),
      GoRoute(
        path: '/provider/bookings',
        name: RouteNames.providerBookings,
        builder: (context, state) {
          return ProviderBookingsScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/analytics',
        name: RouteNames.providerAnalytics,
        builder: (context, state) {
          return ProviderAnalyticsScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/messages',
        name: RouteNames.providerMessages,
        builder: (context, state) {
          return ProviderChatListScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/messages/:conversationId',
        name: RouteNames.providerChatDetail,
        builder: (context, state) {
          final conversationId = int.tryParse(
            state.pathParameters['conversationId'] ?? '',
          );

          final initialConversation = state.extra is ChatConversationModel
              ? state.extra as ChatConversationModel
              : null;

          if (conversationId == null) {
            return const _RouteErrorPlaceholder(
              message: 'No pudimos abrir esta conversación.',
            );
          }

          return ProviderChatScreen(
            authController: _authController,
            conversationId: conversationId,
            initialConversation: initialConversation,
          );
        },
      ),
      GoRoute(
        path: '/provider/profile',
        name: RouteNames.providerProfile,
        builder: (context, state) {
          return ProviderProfileScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/settings',
        name: RouteNames.providerSettings,
        builder: (context, state) {
          return ProviderSettingsScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/customer/profile/help-center',
        name: 'customerHelpCenter',
        builder: (context, state) {
          return const CustomerHelpCenterScreen();
        },
      ),

      GoRoute(
        path: '/customer/profile/terms',
        name: 'customerTermsConditions',
        builder: (context, state) {
          return const CustomerTermsConditionsScreen();
        },
      ),

    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authStatus = _authController.status;

    final currentPath = state.uri.path;
    final currentLocation = state.matchedLocation;

    if (currentPath == '/forgot-password' ||
        currentPath == '/reset-password' ||
        currentLocation == '/forgot-password' ||
        currentLocation == '/reset-password') {
      return null;
    }

    final isChecking = authStatus == AuthStatus.checking;
    final isAuthenticated = authStatus == AuthStatus.authenticated;

    final isPublicExperienceRoute =
        currentLocation.startsWith('/experiences/');

    final publicRoutes = <String>{
      '/',
      '/welcome',
      '/login',
      '/forgot-password',
      '/reset-password',
      '/register',
      '/client/explore',
      '/client/bookings',
      '/client/favorites',
      '/customer/dashboard',
      '/affiliate/register',
      '/provider/register',
      '/provider/login',
    };

    final isPublicRoute =
        publicRoutes.contains(currentLocation) || isPublicExperienceRoute;

    final authRoutes = <String>{
      '/',
      '/welcome',
      '/login',
      '/register',
      '/affiliate/register',
      '/provider/register',
      '/provider/login',
    };

    final isAuthRoute = authRoutes.contains(currentLocation);

    if (isChecking) {
      return currentLocation == '/' ? null : '/';
    }

    if (!isAuthenticated) {
      if (isPublicRoute) {
        return null;
      }

      return '/login';
    }

    final normalizedUserType = _normalizeUserTypeForRouter(
      _authController.userType,
    );

    final isProvider = normalizedUserType == 'provider';
    final isCustomer = normalizedUserType == 'customer';

    final isProviderPrivateRoute = currentLocation.startsWith('/provider/') &&
        currentLocation != '/provider/register' &&
        currentLocation != '/provider/login' &&
        currentLocation != '/provider/verification-pending';

    if (isProvider) {
      final providerStatus = _normalizeProviderStatus(
        _authController.providerStatus,
      );

      if (isAuthRoute) {
        return _providerHomePath(providerStatus);
      }

      if (isProviderPrivateRoute && providerStatus != 'approved') {
        return '/provider/verification-pending';
      }

      if (currentLocation == '/provider/verification-pending' &&
          providerStatus == 'approved') {
        return '/provider/dashboard';
      }

      return null;
    }

    if (isCustomer) {
      if (isAuthRoute) {
        final redirect = _safeRedirectPath(state);

        if (redirect != null) {
          return redirect;
        }

        return '/client/explore';
      }

      if (isProviderPrivateRoute ||
          currentLocation == '/provider/verification-pending') {
        return '/client/explore';
      }

      return null;
    }

    if (isAuthRoute) {
      final redirect = _safeRedirectPath(state);

      if (redirect != null) {
        return redirect;
      }

      return '/client/explore';
    }

    if (isProviderPrivateRoute ||
        currentLocation == '/provider/verification-pending') {
      return '/client/explore';
    }

    return null;
  }

  String? _safeRedirectPath(GoRouterState state) {
    final redirect = state.uri.queryParameters['redirect'];

    if (redirect == null || redirect.trim().isEmpty) {
      return null;
    }

    if (!redirect.startsWith('/') || redirect.startsWith('//')) {
      return null;
    }

    return redirect;
  }

  String _normalizeUserTypeForRouter(String? userType) {
    final type = userType?.trim().toLowerCase() ?? '';

    if (type == 'provider' || type == 'affiliate' || type == 'afiliado') {
      return 'provider';
    }

    if (type == 'customer' || type == 'client' || type == 'user') {
      return 'customer';
    }

    return type.isEmpty ? 'customer' : type;
  }

  String _normalizeProviderStatus(String? providerStatus) {
    final status = providerStatus?.trim().toLowerCase() ?? '';

    if (status.isEmpty) {
      return 'pending';
    }

    return status;
  }

  String _providerHomePath(String? providerStatus) {
    final status = _normalizeProviderStatus(providerStatus);

    if (status == 'approved') {
      return '/provider/dashboard';
    }

    return '/provider/verification-pending';
  }
}

  class _PublicExperienceDetailLoader extends StatefulWidget {
    final int experienceId;
    final AuthController authController;
    final bool openBookingReview;
    final int? initialScheduleId;
    final int? initialTravelers;

    const _PublicExperienceDetailLoader({
      required this.experienceId,
      required this.authController,
      required this.openBookingReview,
      required this.initialScheduleId,
      required this.initialTravelers,
    });

    @override
    State<_PublicExperienceDetailLoader> createState() =>
        _PublicExperienceDetailLoaderState();
  }

  class _PublicExperienceDetailLoaderState
      extends State<_PublicExperienceDetailLoader> {
    final ExploreController _controller = ExploreController();

    bool _isLoading = true;
    String? _errorMessage;
    CustomerExperienceModel? _experience;

    @override
    void initState() {
      super.initState();
      _loadExperience();
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    Future<void> _loadExperience() async {
      try {
        final experience = await _controller.getExperienceDetail(
          widget.experienceId,
        );

        if (!mounted) return;

        setState(() {
          _experience = experience;
          _isLoading = false;
          _errorMessage = null;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'No pudimos cargar esta experiencia.';
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      if (_isLoading) {
        return const Scaffold(
          backgroundColor: Color(0xFFF8F8F8),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_errorMessage != null || _experience == null) {
        return _RouteErrorPlaceholder(
          message: _errorMessage ?? 'Experiencia no encontrada.',
        );
      }

      final experience = _experience!;

      return ExperienceDetailScreen(
        experience: experience,
        authController: widget.authController,
        initialIsFavorite: _controller.isFavorite(experience.id),
        initialScheduleId: widget.initialScheduleId,
        initialTravelers: widget.initialTravelers,
        openBookingReview: widget.openBookingReview,
        onFavoriteChanged: (isFavorite) {
          if (_controller.isFavorite(experience.id) != isFavorite) {
            _controller.toggleFavorite(experience.id);
          }
        },
      );
    }
  }

class _RouteErrorPlaceholder extends StatelessWidget {
  const _RouteErrorPlaceholder({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta inválida'),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}

class _SimpleProviderPlaceholder extends StatelessWidget {
  const _SimpleProviderPlaceholder({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}