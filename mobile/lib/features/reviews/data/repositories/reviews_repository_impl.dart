import '../datasources/reviews_remote_data_source.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../models/review_model.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource remoteDataSource;

  ReviewsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> submitReview(Review review) async {
    final reviewModel = ReviewModel(
      sessionId: review.sessionId,
      restaurantId: review.restaurantId,
      ratingOverall: review.ratingOverall,
      ratingFoodQuality: review.ratingFoodQuality,
      ratingValue: review.ratingValue,
      ratingService: review.ratingService,
      ratingAmbiance: review.ratingAmbiance,
      ratingGroupFriendliness: review.ratingGroupFriendliness,
      reviewText: review.reviewText,
    );
    await remoteDataSource.submitReview(reviewModel);
  }

  @override
  Future<List<Review>> getRecentReviews() async {
    return await remoteDataSource.getRecentReviews();
  }

  @override
  Future<void> submitUserReview({
    required String sessionId,
    required String targetUserId,
    required int rating,
    required String reviewText,
  }) async {
    await remoteDataSource.submitUserReview({
      'session_id': sessionId,
      'target_user_id': targetUserId,
      'rating': rating,
      'review_text': reviewText,
    });
  }
}
