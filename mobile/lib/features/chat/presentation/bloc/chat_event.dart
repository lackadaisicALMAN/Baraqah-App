import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class JoinChatRoomRequested extends ChatEvent {
  final String roomId;
  const JoinChatRoomRequested(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class SendChatMessageRequested extends ChatEvent {
  final String roomId;
  final String text;
  final bool isLocation;

  const SendChatMessageRequested(
      {required this.roomId, required this.text, this.isLocation = false});

  @override
  List<Object?> get props => [roomId, text, isLocation];
}

class FetchChatMessagesRequested extends ChatEvent {}
