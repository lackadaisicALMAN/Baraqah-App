import 'package:equatable/equatable.dart';

enum MessageType { text, location }

class ChatMessage extends Equatable {
  final String id;
  final String sender;
  final String text;
  final MessageType type;
  final DateTime createdAt;

  const ChatMessage(
      {required this.id,
      required this.sender,
      required this.text,
      required this.type,
      required this.createdAt});

  @override
  List<Object?> get props => [id, sender, text, type, createdAt];
}
