import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

/// Pantalla inicial de carga.
///
/// Esta pantalla ahora funciona como un splash screen visual.
///
/// Flujo esperado:
///
/// 1. La app abre.
/// 2. Se muestra el logo de AndanDO.
/// 3. Se muestra una pequeña animación de carga.
/// 4. Después de 2 segundos redirige a /login.
///
/// Importante:
/// Esta pantalla NO es el login.
/// Solo es una transición visual inicial.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Timer que controla la redirección automática.
  ///
  /// Lo guardamos en una variable para poder cancelarlo en dispose().
  /// Eso evita errores si el usuario sale de la pantalla antes de los 2 segundos.
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();

    /// Esperamos 2 segundos antes de mandar al usuario al login.
    ///
    /// Este comportamiento viene del diseño nuevo de Figma/React.
    _redirectTimer = Timer(const Duration(seconds: 2), () {
      /// mounted verifica que el widget todavía existe en pantalla.
      ///
      /// Si el widget ya fue destruido, no debemos navegar.
      if (!mounted) return;

      context.goNamed(RouteNames.login);
    });
  }

  @override
  void dispose() {
    /// Cancelamos el timer para evitar que intente navegar
    /// cuando la pantalla ya no existe.
    _redirectTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Logo con animación suave tipo pulse.
                _PulsingLogo(),

                SizedBox(height: 24),

                Text(
                  'Descubre República Dominicana',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 48),

                /// Tres puntos animados de carga.
                _LoadingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo con animación de pulso.
///
/// Esto imita el comportamiento:
/// animate-pulse
///
/// del diseño en React/Tailwind.
class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo();

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    /// Controlador que se repite constantemente.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    /// Escala suave del logo.
    ///
    /// Va de 96% a 104% de tamaño.
    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    /// Opacidad suave del logo.
    ///
    /// Va de 75% a 100%.
    _opacityAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    /// Siempre liberamos AnimationController.
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Image.asset(
          'assets/images/logos/andando_logo.png',
          width: 256,
          fit: BoxFit.contain,

          /// Fallback por si el logo todavía no está agregado.
          ///
          /// Esto evita que la pantalla se quede rota durante desarrollo.
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'AndanDO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animación de tres puntos de carga.
///
/// Cada punto sube y baja con un pequeño retraso visual.
/// Esto reemplaza el animate-bounce de Tailwind.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    /// Controlador de animación repetitiva.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    /// Liberamos el controlador cuando el widget se destruye.
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            /// Calculamos un desfase para que cada punto anime
            /// en momentos diferentes.
            final phase = (_controller.value * 2 * math.pi) + (index * 0.8);

            /// Si el seno es positivo, el punto sube.
            /// Si es negativo, lo dejamos en 0 para simular bounce.
            final double offsetY = -6.0 * math.max(0.0, math.sin(phase));

            return Transform.translate(
              offset: Offset(0.0, offsetY),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}