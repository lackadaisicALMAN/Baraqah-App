import '../entities/leaderboard_entry.dart';
import '../repositories/social_repository.dart';

class FetchLeaderboardUseCase {
  final SocialRepository repository;
  FetchLeaderboardUseCase(this.repository);

  Future<List<LeaderboardEntry>> call() async {
    return repository.fetchLeaderboard();
  }
}
