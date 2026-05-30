import 'experience_review_model.dart';

class ExperienceReviewsResponse {
  final double averageRating;
  final int totalReviews;
  final List<ExperienceReviewModel> reviews;

  const ExperienceReviewsResponse({
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });
}