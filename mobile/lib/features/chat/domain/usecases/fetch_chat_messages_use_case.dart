import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class FetchChatMessagesUseCase {
  final ChatRepository repository;
  FetchChatMessagesUseCase(this.repository);

  List<ChatMessage> call() {
    return repository.getMessages();
  }
}
