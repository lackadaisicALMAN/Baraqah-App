import '../repositories/chat_repository.dart';

class JoinRoomUseCase {
  final ChatRepository repository;
  JoinRoomUseCase(this.repository);

  Future<void> call(String roomId) async {
    await repository.connectToRoom(roomId);
  }
}
