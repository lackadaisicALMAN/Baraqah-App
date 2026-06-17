import 'package:baraqah_mobile/core/constants/api_endpoints.dart';
import 'package:baraqah_mobile/core/network/api_client.dart';
import '../models/review_model.dart';

class ReviewsRemoteDataSource {
  final ApiClient apiClient;
  ReviewsRemoteDataSource({required this.apiClient});

  Future<void> submitReview(ReviewModel review) async {
    await apiClient.post(ApiEndpoints.reviews, data: review.toJson());
  }

  Future<List<ReviewModel>> getRecentReviews() async {
    final response = await apiClient.get('${ApiEndpoints.reviews}/recent');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => ReviewModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> submitUserReview(Map<String, dynamic> payload) async {
    await apiClient.post(ApiEndpoints.userReviews, data: payload);
  }
}
