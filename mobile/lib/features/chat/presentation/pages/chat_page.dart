import 'package:baraqah_mobile/core/widgets/app_button.dart';
import 'package:baraqah_mobile/core/widgets/loading_indicator.dart';
import 'package:baraqah_mobile/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatPage extends StatefulWidget {
  static const String routeName = '/chat';
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _roomController =
      TextEditingController(text: 'global');
  bool _isLocation = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Group Chat')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room ID')),
              const SizedBox(height: 12),
              AppButton(label: 'Join Room', onPressed: _joinRoom),
              const SizedBox(height: 16),
              Expanded(child:
                  BlocBuilder<ChatBloc, ChatState>(builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: LoadingIndicator());
                }
                if (state is ChatFailure) {
                  return Center(child: Text(state.message));
                }
                if (state is ChatMessagesLoadSuccess) {
                  return _MessageList(messages: state.messages);
                }
                return const Center(
                    child: Text('Join a room to see messages.'));
              })),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _textController,
                        decoration:
                            const InputDecoration(labelText: 'Message'))),
                const SizedBox(width: 8),
                IconButton(
                    icon: Icon(_isLocation ? Icons.location_on : Icons.chat),
                    onPressed: () =>
                        setState(() => _isLocation = !_isLocation)),
              ]),
              const SizedBox(height: 12),
              AppButton(label: 'Send', onPressed: _sendMessage),
            ],
          ),
        ),
      ),
    );
  }

  void _joinRoom() {
    context
        .read<ChatBloc>()
        .add(JoinChatRoomRequested(_roomController.text.trim()));
  }

  void _sendMessage() {
    context.read<ChatBloc>().add(SendChatMessageRequested(
        roomId: _roomController.text.trim(),
        text: _textController.text.trim(),
        isLocation: _isLocation));
    _textController.clear();
  }
}

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  const _MessageList({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          title: Text(message.sender),
          subtitle: Text(message.type == MessageType.location
              ? 'Location: ${message.text}'
              : message.text),
          trailing: Text(message.createdAt.toLocal().toIso8601String()),
        );
      },
    );
  }
}
