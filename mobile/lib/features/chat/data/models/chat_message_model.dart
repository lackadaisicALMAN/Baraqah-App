import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel(
      {required String id,
      required String sender,
      required String text,
      required MessageType type,
      required DateTime createdAt})
      : super(
            id: id,
            sender: sender,
            text: text,
            type: type,
            createdAt: createdAt);

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'text';
    return ChatMessageModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      sender: json['sender'] ?? 'Anonymous',
      text: json['text'] ?? json['message'] ?? '',
      type: rawType == 'location' ? MessageType.location : MessageType.text,
      createdAt: DateTime.parse(
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'type': type == MessageType.location ? 'location' : 'text',
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
