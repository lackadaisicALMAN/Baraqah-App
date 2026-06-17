import 'package:equatable/equatable.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/leaderboard_entry.dart';

abstract class SocialState extends Equatable {
  const SocialState();

  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {}

class SocialLoading extends SocialState {}

class FriendsLoadSuccess extends SocialState {
  final List<Friend> friends;
  const FriendsLoadSuccess(this.friends);

  @override
  List<Object?> get props => [friends];
}

class LeaderboardLoadSuccess extends SocialState {
  final List<LeaderboardEntry> entries;
  const LeaderboardLoadSuccess(this.entries);

  @override
  List<Object?> get props => [entries];
}

class SocialFailure extends SocialState {
  final String message;
  const SocialFailure(this.message);

  @override
  List<Object?> get props => [message];
}
