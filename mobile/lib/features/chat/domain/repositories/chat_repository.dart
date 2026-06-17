import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<void> connectToRoom(String roomId);
  Future<void> disconnect();
  Future<void> sendMessage(String roomId, String text,
      {bool isLocation = false});
  List<ChatMessage> getMessages();
}
