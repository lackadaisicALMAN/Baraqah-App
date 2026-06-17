import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel(
      {required String id,
      required String name,
      required int score,
      required int rank})
      : super(id: id, name: name, score: score, rank: rank);

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? 'Anonymous',
      score: json['score'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }
}
