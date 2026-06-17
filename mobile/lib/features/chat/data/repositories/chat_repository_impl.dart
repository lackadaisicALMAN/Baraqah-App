import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> connectToRoom(String roomId) async {
    await remoteDataSource.connect(roomId);
  }

  @override
  Future<void> disconnect() async {
    remoteDataSource.disconnect();
  }

  @override
  Future<void> sendMessage(String roomId, String text,
      {bool isLocation = false}) async {
    await remoteDataSource.sendMessage(roomId, text, isLocation: isLocation);
  }

  @override
  List<ChatMessage> getMessages() {
    return remoteDataSource.getMessages();
  }
}
