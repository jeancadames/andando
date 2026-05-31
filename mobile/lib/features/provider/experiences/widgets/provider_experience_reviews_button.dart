import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../auth/application/auth_controller.dart';
import '../services/provider_experience_reviews_service.dart';

class ProviderExperienceReviewsButton extends StatefulWidget {
  final AuthController authController;
  final int experienceId;
  final String experienceTitle;

  const ProviderExperienceReviewsButton({
    super.key,
    required this.authController,
    required this.experienceId,
    required this.experienceTitle,
  });

  @override
  State<ProviderExperienceReviewsButton> createState() =>
      _ProviderExperienceReviewsButtonState();
}

class _ProviderExperienceReviewsButtonState
    extends State<ProviderExperienceReviewsButton> {
  final ProviderExperienceReviewsService _service =
      ProviderExperienceReviewsService();

  double? _averageRating;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void didUpdateWidget(covariant ProviderExperienceReviewsButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.experienceId != widget.experienceId) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _service.getSummary(
        experienceId: widget.experienceId,
        token: widget.authController.token,
      );

      if (!mounted) return;

      setState(() {
        _averageRating = summary.averageRating;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _averageRating = 0;
        _isLoading = false;
      });
    }
  }

  void _openReviews() {
    context.goNamed(
      RouteNames.providerExperienceReviews,
      pathParameters: {
        'id': widget.experienceId.toString(),
      },
      queryParameters: {
        'title': widget.experienceTitle,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _openReviews,
        icon: const Icon(
          Icons.star_border_rounded,
          size: 20,
        ),
        label: const Text(
          'Ver Reseñas',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}