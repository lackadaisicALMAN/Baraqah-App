import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  final String id;
  final String name;
  final int score;
  final int rank;

  const LeaderboardEntry(
      {required this.id,
      required this.name,
      required this.score,
      required this.rank});

  @override
  List<Object?> get props => [id, name, score, rank];
}
