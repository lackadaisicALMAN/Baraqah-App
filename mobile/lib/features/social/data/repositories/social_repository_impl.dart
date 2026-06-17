import '../datasources/social_remote_data_source.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  final SocialRemoteDataSource remoteDataSource;

  SocialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Friend>> fetchFriends() async {
    return remoteDataSource.fetchFriends();
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    return remoteDataSource.fetchLeaderboard();
  }
}
