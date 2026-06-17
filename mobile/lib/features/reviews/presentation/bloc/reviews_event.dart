import 'package:equatable/equatable.dart';

abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReviewRequested extends ReviewsEvent {
  final String sessionId;
  final String? restaurantId;
  final int ratingOverall;
  final int? ratingFoodQuality;
  final int? ratingValue;
  final int? ratingService;
  final int? ratingAmbiance;
  final int? ratingGroupFriendliness;
  final String reviewText;

  const SubmitReviewRequested({
    required this.sessionId,
    this.restaurantId,
    required this.ratingOverall,
    this.ratingFoodQuality,
    this.ratingValue,
    this.ratingService,
    this.ratingAmbiance,
    this.ratingGroupFriendliness,
    required this.reviewText,
  });

  @override
  List<Object?> get props => [
        sessionId,
        restaurantId,
        ratingOverall,
        ratingFoodQuality,
        ratingValue,
        ratingService,
        ratingAmbiance,
        ratingGroupFriendliness,
        reviewText,
      ];
}

class FetchRecentReviewsRequested extends ReviewsEvent {}

class SubmitUserReviewRequested extends ReviewsEvent {
  final String sessionId;
  final String targetUserId;
  final int rating;
  final String reviewText;

  const SubmitUserReviewRequested({
    required this.sessionId,
    required this.targetUserId,
    required this.rating,
    required this.reviewText,
  });

  @override
  List<Object?> get props => [sessionId, targetUserId, rating, reviewText];
}
