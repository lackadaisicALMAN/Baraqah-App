import 'package:equatable/equatable.dart';

abstract class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

class FetchFriendsRequested extends SocialEvent {}

class FetchLeaderboardRequested extends SocialEvent {}
