import '../entities/review.dart';
import '../repositories/reviews_repository.dart';

class FetchRecentReviewsUseCase {
  final ReviewsRepository repository;
  FetchRecentReviewsUseCase(this.repository);

  Future<List<Review>> call() async {
    return await repository.getRecentReviews();
  }
}
