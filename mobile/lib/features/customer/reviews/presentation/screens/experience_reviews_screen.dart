import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/experience_reviews_remote_datasource.dart';
import '../../data/models/experience_review_model.dart';
import '../../data/models/experience_reviews_response.dart';

class ExperienceReviewsScreen extends StatefulWidget {
  const ExperienceReviewsScreen({
    super.key,
    required this.experienceId,
    required this.averageRating,
    required this.totalReviews,
  });

  final int experienceId;
  final double averageRating;
  final int totalReviews;

  @override
  State<ExperienceReviewsScreen> createState() =>
      _ExperienceReviewsScreenState();
}

class _ExperienceReviewsScreenState extends State<ExperienceReviewsScreen> {
  final ExperienceReviewsRemoteDataSource _dataSource =
      ExperienceReviewsRemoteDataSource();

  late Future<ExperienceReviewsResponse> _futureReviews;

  @override
  void initState() {
    super.initState();
    _futureReviews = _dataSource.getExperienceReviews(
      experienceId: widget.experienceId,
      limit: 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black,
        ),
        title: const Text(
          'Reseñas',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: FutureBuilder<ExperienceReviewsResponse>(
        future: _futureReviews,
        builder: (context, snapshot) {
          final response = snapshot.data;

          final reviews = response?.reviews ?? [];
          final averageRating =
              response?.averageRating ?? widget.averageRating;
          final totalReviews = response?.totalReviews ?? widget.totalReviews;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              _SummaryCard(
                averageRating: averageRating,
                totalReviews: totalReviews,
                reviews: reviews,
              ),
              const SizedBox(height: 18),
              if (reviews.isEmpty)
                const _EmptyReviewsCard()
              else
                ...reviews.map(
                  (review) => _FullReviewCard(review: review),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  final double averageRating;
  final int totalReviews;
  final List<ExperienceReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    int countFor(int rating) {
      return reviews.where((item) => item.rating == rating).length;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Text(
            'Opiniones de viajeros',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFACC15),
                size: 34,
              ),
              const SizedBox(width: 8),
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$totalReviews reseñas',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          for (final rating in [5, 4, 3, 2, 1])
            _DistributionRow(
              rating: rating,
              count: countFor(rating),
              total: reviews.isEmpty ? 1 : reviews.length,
            ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.rating,
    required this.count,
    required this.total,
  });

  final int rating;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total <= 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$rating',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const Icon(
            Icons.star_rounded,
            color: Color(0xFFFACC15),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF003B73),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullReviewCard extends StatelessWidget {
  const _FullReviewCard({
    required this.review,
  });

  final ExperienceReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE0ECF7),
                child: Text(
                  review.customerName.trim().isEmpty
                      ? 'V'
                      : review.customerName.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF003B73),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 22,
                color: const Color(0xFFFACC15),
              ),
            ),
          ),
          if (review.comment != null &&
              review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyReviewsCard extends StatelessWidget {
  const _EmptyReviewsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Esta experiencia todavía no tiene comentarios.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}