import '../entities/friend.dart';
import '../entities/leaderboard_entry.dart';

abstract class SocialRepository {
  Future<List<Friend>> fetchFriends();
  Future<List<LeaderboardEntry>> fetchLeaderboard();
}
