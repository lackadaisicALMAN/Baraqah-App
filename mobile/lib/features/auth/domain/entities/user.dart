import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final String? avatarUrl;
  final double baraqahScore;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.bio,
    this.avatarUrl,
    this.baraqahScore = 5.0,
  });

  @override
  List<Object?> get props => [id, name, email, phone, bio, avatarUrl, baraqahScore];
}
