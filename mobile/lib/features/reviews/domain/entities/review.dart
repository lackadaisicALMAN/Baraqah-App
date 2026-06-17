import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String sessionId;
  final String? restaurantId;
  final String? restaurantName;
  final String? authorName;
  final double? authorScore;
  final int ratingOverall;
  final int? ratingFoodQuality;
  final int? ratingValue;
  final int? ratingService;
  final int? ratingAmbiance;
  final int? ratingGroupFriendliness;
  final String reviewText;
  final List<String> tags;
  final DateTime? createdAt;

  const Review({
    required this.sessionId,
    this.restaurantId,
    this.restaurantName,
    this.authorName,
    this.authorScore,
    required this.ratingOverall,
    this.ratingFoodQuality,
    this.ratingValue,
    this.ratingService,
    this.ratingAmbiance,
    this.ratingGroupFriendliness,
    required this.reviewText,
    this.tags = const [],
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        sessionId,
        restaurantId,
        restaurantName,
        authorName,
        authorScore,
        ratingOverall,
        ratingFoodQuality,
        ratingValue,
        ratingService,
        ratingAmbiance,
        ratingGroupFriendliness,
        reviewText,
        tags,
        createdAt,
      ];
}
