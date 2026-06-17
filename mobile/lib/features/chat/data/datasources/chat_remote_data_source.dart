import 'package:baraqah_mobile/core/constants/api_endpoints.dart';
import 'package:baraqah_mobile/core/network/socket_client.dart';
import 'package:baraqah_mobile/core/storage/secure_storage.dart';
import '../models/chat_message_model.dart';

class ChatRemoteDataSource {
  final SecureStorage secureStorage;
  late final SocketClient _socket;
  final List<ChatMessageModel> _messages = [];

  ChatRemoteDataSource({required this.secureStorage});

  Future<void> connect(String roomId) async {
    final token = await secureStorage.readToken();
    _socket = SocketClient(ApiEndpoints.socketUrl, token: token);
    _socket.connect();
    _socket.on('message', (data) {
      final model =
          ChatMessageModel.fromJson(Map<String, dynamic>.from(data as Map));
      _messages.add(model);
    });
    _socket.emit('join', {'roomId': roomId});
  }

  void disconnect() {
    _socket.disconnect();
  }

  Future<void> sendMessage(String roomId, String text,
      {bool isLocation = false}) async {
    final payload = {
      'roomId': roomId,
      'text': text,
      'type': isLocation ? 'location' : 'text'
    };
    _socket.emit('message', payload);
  }

  List<ChatMessageModel> getMessages() {
    return List.unmodifiable(_messages);
  }
}
