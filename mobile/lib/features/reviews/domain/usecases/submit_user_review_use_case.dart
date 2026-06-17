import '../repositories/reviews_repository.dart';

class SubmitUserReviewUseCase {
  final ReviewsRepository repository;
  SubmitUserReviewUseCase(this.repository);

  Future<void> call({
    required String sessionId,
    required String targetUserId,
    required int rating,
    required String reviewText,
  }) async {
    await repository.submitUserReview(
      sessionId: sessionId,
      targetUserId: targetUserId,
      rating: rating,
      reviewText: reviewText,
    );
  }
}
