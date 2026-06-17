import '../entities/review.dart';
import '../repositories/reviews_repository.dart';

class SubmitReviewUseCase {
  final ReviewsRepository repository;
  SubmitReviewUseCase(this.repository);

  Future<void> call(Review review) async {
    await repository.submitReview(review);
  }
}
