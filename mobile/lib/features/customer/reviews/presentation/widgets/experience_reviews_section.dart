import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/experience_reviews_remote_datasource.dart';
import '../../data/models/experience_review_model.dart';
import '../../data/models/experience_reviews_response.dart';

class ExperienceReviewsSection extends StatefulWidget {
  const ExperienceReviewsSection({
    super.key,
    required this.experienceId,
    required this.averageRating,
    required this.totalReviews,
    this.onSummaryChanged,
  });

  final int experienceId;
  final double averageRating;
  final int totalReviews;
  final void Function(double rating, int totalReviews)? onSummaryChanged;

  @override
  State<ExperienceReviewsSection> createState() =>
      _ExperienceReviewsSectionState();
}

class _ExperienceReviewsSectionState extends State<ExperienceReviewsSection> {
  final ExperienceReviewsRemoteDataSource _dataSource =
      ExperienceReviewsRemoteDataSource();

  late Future<ExperienceReviewsResponse> _futureReviews;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _futureReviews = _dataSource.getExperienceReviews(
      experienceId: widget.experienceId,
      limit: 3,
    );
  }

  void _refreshReviews() {
    setState(_loadReviews);
  }

  void _notifySummaryChanged(ExperienceReviewsResponse response) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.onSummaryChanged?.call(
        response.averageRating,
        response.totalReviews,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExperienceReviewsResponse>(
      future: _futureReviews,
      builder: (context, snapshot) {
        final response = snapshot.data;

        if (response != null) {
          _notifySummaryChanged(response);
        }

        final reviews = response?.reviews ?? [];
        final averageRating = response?.averageRating ?? widget.averageRating;
        final totalReviews = response?.totalReviews ?? widget.totalReviews;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reseñas de viajeros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFACC15),
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($totalReviews reseñas)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (reviews.isEmpty)
                const Text(
                  'Esta experiencia todavía no tiene comentarios.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                )
              else
                ...reviews.map(
                  (review) => _ReviewTile(
                    review: review,
                    onChanged: _refreshReviews,
                  ),
                ),
              if (totalReviews > 3) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      context.push(
                        '/experiences/${widget.experienceId}/reviews',
                        extra: {
                          'averageRating': averageRating,
                          'totalReviews': totalReviews,
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003B73),
                      side: const BorderSide(color: Color(0xFF003B73)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ver todas las reseñas',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.onChanged,
  });

  final ExperienceReviewModel review;
  final VoidCallback onChanged;

  Future<void> _editReview(BuildContext context) async {
    final booking = review.booking;

    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir esta reseña para editar.'),
        ),
      );
      return;
    }

    final edited = await context.push<bool>(
      '/client/bookings/${booking.id}/review',
      extra: booking,
    );

    if (edited == true && context.mounted) {
      onChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reseña actualizada correctamente.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar reseña'),
          content: const Text(
            '¿Seguro que quieres eliminar esta reseña? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final dataSource = ExperienceReviewsRemoteDataSource();
      await dataSource.deleteReview(reviewId: review.id);

      if (!context.mounted) return;

      onChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reseña eliminada correctamente.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE0ECF7),
                child: Text(
                  review.customerName.trim().isEmpty
                      ? 'V'
                      : review.customerName.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF003B73),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: const Color(0xFFFACC15),
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null &&
              review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
          if (review.isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _editReview(context),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF003B73),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}