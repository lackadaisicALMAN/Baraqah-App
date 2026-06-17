import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required String sessionId,
    String? restaurantId,
    String? restaurantName,
    String? authorName,
    double? authorScore,
    required int ratingOverall,
    int? ratingFoodQuality,
    int? ratingValue,
    int? ratingService,
    int? ratingAmbiance,
    int? ratingGroupFriendliness,
    required String reviewText,
    List<String> tags = const [],
    DateTime? createdAt,
  }) : super(
          sessionId: sessionId,
          restaurantId: restaurantId,
          restaurantName: restaurantName,
          authorName: authorName,
          authorScore: authorScore,
          ratingOverall: ratingOverall,
          ratingFoodQuality: ratingFoodQuality,
          ratingValue: ratingValue,
          ratingService: ratingService,
          ratingAmbiance: ratingAmbiance,
          ratingGroupFriendliness: ratingGroupFriendliness,
          reviewText: reviewText,
          tags: tags,
          createdAt: createdAt,
        );

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final ratings = json['ratings'] != null ? Map<String, dynamic>.from(json['ratings'] as Map) : <String, dynamic>{};
    final author = json['author'] != null ? Map<String, dynamic>.from(json['author'] as Map) : <String, dynamic>{};
    final restaurant = json['restaurant'] != null ? Map<String, dynamic>.from(json['restaurant'] as Map) : <String, dynamic>{};

    return ReviewModel(
      sessionId: json['sessionId']?.toString() ?? json['session_id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? json['restaurant_id']?.toString(),
      restaurantName: restaurant['name']?.toString() ?? json['restaurantName']?.toString(),
      authorName: author['full_name']?.toString() ?? json['authorName']?.toString(),
      authorScore: (author['baraqah_score'] as num?)?.toDouble() ?? (json['authorScore'] as num?)?.toDouble(),
      ratingOverall: (ratings['overall'] as num?)?.toInt() ?? (json['ratingOverall'] as num?)?.toInt() ?? 5,
      ratingFoodQuality: (ratings['food_quality'] as num?)?.toInt() ?? (json['ratingFoodQuality'] as num?)?.toInt(),
      ratingValue: (ratings['value'] as num?)?.toInt() ?? (json['ratingValue'] as num?)?.toInt(),
      ratingService: (ratings['service'] as num?)?.toInt() ?? (json['ratingService'] as num?)?.toInt(),
      ratingAmbiance: (ratings['ambiance'] as num?)?.toInt() ?? (json['ratingAmbiance'] as num?)?.toInt(),
      ratingGroupFriendliness: (ratings['group_friendliness'] as num?)?.toInt() ?? (json['ratingGroupFriendliness'] as num?)?.toInt(),
      reviewText: json['review_text']?.toString() ?? json['reviewText']?.toString() ?? json['review_text']?.toString() ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : (json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'restaurant_id': restaurantId,
      'ratings': {
        'overall': ratingOverall,
        if (ratingFoodQuality != null) 'food_quality': ratingFoodQuality,
        if (ratingValue != null) 'value': ratingValue,
        if (ratingService != null) 'service': ratingService,
        if (ratingAmbiance != null) 'ambiance': ratingAmbiance,
        if (ratingGroupFriendliness != null) 'group_friendliness': ratingGroupFriendliness,
      },
      'review_text': reviewText,
      'tags': tags,
    };
  }
}
