import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/review.dart';
import '../../domain/usecases/submit_review_use_case.dart';
import '../../domain/usecases/fetch_recent_reviews_use_case.dart';
import '../../domain/usecases/submit_user_review_use_case.dart';
import 'reviews_event.dart';
import 'reviews_state.dart';

class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final SubmitReviewUseCase submitReviewUseCase;
  final FetchRecentReviewsUseCase fetchRecentReviewsUseCase;
  final SubmitUserReviewUseCase submitUserReviewUseCase;

  ReviewsBloc({
    required this.submitReviewUseCase,
    required this.fetchRecentReviewsUseCase,
    required this.submitUserReviewUseCase,
  }) : super(ReviewsInitial()) {
    on<SubmitReviewRequested>(_onSubmitReview);
    on<FetchRecentReviewsRequested>(_onFetchRecentReviews);
    on<SubmitUserReviewRequested>(_onSubmitUserReview);
  }

  Future<void> _onSubmitReview(
      SubmitReviewRequested event, Emitter<ReviewsState> emit) async {
    emit(ReviewsLoading());
    try {
      final review = Review(
        sessionId: event.sessionId,
        restaurantId: event.restaurantId,
        ratingOverall: event.ratingOverall,
        ratingFoodQuality: event.ratingFoodQuality,
        ratingValue: event.ratingValue,
        ratingService: event.ratingService,
        ratingAmbiance: event.ratingAmbiance,
        ratingGroupFriendliness: event.ratingGroupFriendliness,
        reviewText: event.reviewText,
      );
      await submitReviewUseCase.call(review);
      emit(ReviewsSuccess());
    } catch (error) {
      emit(ReviewsFailure(error.toString()));
    }
  }

  Future<void> _onFetchRecentReviews(
      FetchRecentReviewsRequested event, Emitter<ReviewsState> emit) async {
    emit(ReviewsLoading());
    try {
      final reviews = await fetchRecentReviewsUseCase.call();
      emit(RecentReviewsLoadSuccess(reviews));
    } catch (error) {
      emit(ReviewsFailure(error.toString()));
    }
  }

  Future<void> _onSubmitUserReview(
      SubmitUserReviewRequested event, Emitter<ReviewsState> emit) async {
    emit(ReviewsLoading());
    try {
      await submitUserReviewUseCase.call(
        sessionId: event.sessionId,
        targetUserId: event.targetUserId,
        rating: event.rating,
        reviewText: event.reviewText,
      );
      emit(ReviewsSuccess());
    } catch (error) {
      emit(ReviewsFailure(error.toString()));
    }
  }
}
