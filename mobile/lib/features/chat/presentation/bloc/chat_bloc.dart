import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/fetch_chat_messages_use_case.dart';
import '../../domain/usecases/join_room_use_case.dart';
import '../../domain/usecases/send_message_use_case.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FetchChatMessagesUseCase fetchChatMessagesUseCase;
  final JoinRoomUseCase joinRoomUseCase;
  final SendMessageUseCase sendMessageUseCase;

  ChatBloc(
      {required this.fetchChatMessagesUseCase,
      required this.joinRoomUseCase,
      required this.sendMessageUseCase})
      : super(ChatInitial()) {
    on<JoinChatRoomRequested>(_onJoinRoom);
    on<SendChatMessageRequested>(_onSendMessage);
    on<FetchChatMessagesRequested>(_onFetchMessages);
  }

  Future<void> _onJoinRoom(
      JoinChatRoomRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      await joinRoomUseCase.call(event.roomId);
      final messages = fetchChatMessagesUseCase.call();
      emit(ChatMessagesLoadSuccess(messages));
    } catch (error) {
      emit(ChatFailure(error.toString()));
    }
  }

  Future<void> _onSendMessage(
      SendChatMessageRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      await sendMessageUseCase.call(event.roomId, event.text,
          isLocation: event.isLocation);
      final messages = fetchChatMessagesUseCase.call();
      emit(ChatMessagesLoadSuccess(messages));
    } catch (error) {
      emit(ChatFailure(error.toString()));
    }
  }

  Future<void> _onFetchMessages(
      FetchChatMessagesRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final messages = fetchChatMessagesUseCase.call();
      emit(ChatMessagesLoadSuccess(messages));
    } catch (error) {
      emit(ChatFailure(error.toString()));
    }
  }
}
