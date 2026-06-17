import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String name,
    required String email,
    required String phone,
    String? bio,
    String? avatarUrl,
    double baraqahScore = 5.0,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          bio: bio,
          avatarUrl: avatarUrl,
          baraqahScore: baraqahScore,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userMap =
        json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;
    final data =
        userMap.containsKey('data') && userMap['data'] is Map<String, dynamic>
            ? userMap['data'] as Map<String, dynamic>
            : userMap;
    final profileMap = json.containsKey('profile')
        ? json['profile'] as Map<String, dynamic>?
        : null;

    return UserModel(
      id: data['id']?.toString() ?? '',
      name: data['full_name']?.toString() ?? data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone:
          data['phone_number']?.toString() ?? data['phone']?.toString() ?? '',
      bio: data['bio']?.toString() ?? profileMap?['bio']?.toString() ?? '',
      avatarUrl: data['avatar_url']?.toString(),
      baraqahScore: (() {
        final raw = data['baraqah_score'];
        if (raw == null) return 5.0;
        if (raw is num) return raw.toDouble();
        if (raw is String) {
          final parsed = double.tryParse(raw);
          if (parsed != null) return parsed;
        }
        return 5.0;
      })(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'phone_number': phone,
      'bio': bio,
      'avatar_url': avatarUrl,
      'baraqah_score': baraqahScore,
    };
  }
}
