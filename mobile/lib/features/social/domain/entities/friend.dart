import 'package:equatable/equatable.dart';

class Friend extends Equatable {
  final String id;
  final String name;
  final int mutualSessions;
  final int score;

  const Friend(
      {required this.id,
      required this.name,
      required this.mutualSessions,
      required this.score});

  @override
  List<Object?> get props => [id, name, mutualSessions, score];
}
