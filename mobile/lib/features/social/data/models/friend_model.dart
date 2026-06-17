import '../../domain/entities/friend.dart';

class FriendModel extends Friend {
  const FriendModel(
      {required String id,
      required String name,
      required int mutualSessions,
      required int score})
      : super(id: id, name: name, mutualSessions: mutualSessions, score: score);

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      mutualSessions: json['mutualSessions'] ?? 0,
      score: json['score'] ?? 0,
    );
  }
}
