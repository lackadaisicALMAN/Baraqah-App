import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<void> call(String roomId, String text,
      {bool isLocation = false}) async {
    await repository.sendMessage(roomId, text, isLocation: isLocation);
  }
}
