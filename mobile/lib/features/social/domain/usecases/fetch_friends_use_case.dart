import '../entities/friend.dart';
import '../repositories/social_repository.dart';

class FetchFriendsUseCase {
  final SocialRepository repository;
  FetchFriendsUseCase(this.repository);

  Future<List<Friend>> call() async {
    return repository.fetchFriends();
  }
}
