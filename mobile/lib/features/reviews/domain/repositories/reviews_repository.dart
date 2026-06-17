import '../entities/review.dart';

abstract class ReviewsRepository {
  Future<void> submitReview(Review review);
  Future<List<Review>> getRecentReviews();
  Future<void> submitUserReview({
    required String sessionId,
    required String targetUserId,
    required int rating,
    required String reviewText,
  });
}
