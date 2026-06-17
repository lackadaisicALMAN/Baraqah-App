import 'package:equatable/equatable.dart';
import '../../domain/entities/review.dart';

abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsSuccess extends ReviewsState {}

class RecentReviewsLoadSuccess extends ReviewsState {
  final List<Review> reviews;
  const RecentReviewsLoadSuccess(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class ReviewsFailure extends ReviewsState {
  final String message;
  const ReviewsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
