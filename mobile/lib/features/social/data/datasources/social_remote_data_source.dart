import 'package:baraqah_mobile/core/constants/api_endpoints.dart';
import 'package:baraqah_mobile/core/network/api_client.dart';
import '../models/friend_model.dart';
import '../models/leaderboard_entry_model.dart';

class SocialRemoteDataSource {
  final ApiClient apiClient;
  SocialRemoteDataSource({required this.apiClient});

  Future<List<FriendModel>> fetchFriends() async {
    final response = await apiClient.get('${ApiEndpoints.social}/friends');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => FriendModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<LeaderboardEntryModel>> fetchLeaderboard() async {
    final response = await apiClient.get('${ApiEndpoints.social}/leaderboard');
    final data = response.data as List<dynamic>;
    return data
        .map((item) =>
            LeaderboardEntryModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
