import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/fetch_friends_use_case.dart';
import '../../domain/usecases/fetch_leaderboard_use_case.dart';
import 'social_event.dart';
import 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final FetchFriendsUseCase fetchFriendsUseCase;
  final FetchLeaderboardUseCase fetchLeaderboardUseCase;

  SocialBloc(
      {required this.fetchFriendsUseCase,
      required this.fetchLeaderboardUseCase})
      : super(SocialInitial()) {
    on<FetchFriendsRequested>(_fetchFriends);
    on<FetchLeaderboardRequested>(_fetchLeaderboard);
  }

  Future<void> _fetchFriends(
      FetchFriendsRequested event, Emitter<SocialState> emit) async {
    emit(SocialLoading());
    try {
      final friends = await fetchFriendsUseCase.call();
      emit(FriendsLoadSuccess(friends));
    } catch (error) {
      emit(SocialFailure(error.toString()));
    }
  }

  Future<void> _fetchLeaderboard(
      FetchLeaderboardRequested event, Emitter<SocialState> emit) async {
    emit(SocialLoading());
    try {
      final entries = await fetchLeaderboardUseCase.call();
      emit(LeaderboardLoadSuccess(entries));
    } catch (error) {
      emit(SocialFailure(error.toString()));
    }
  }
}
