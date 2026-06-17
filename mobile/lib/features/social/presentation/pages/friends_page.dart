import 'package:baraqah_mobile/core/widgets/error_card.dart';
import 'package:baraqah_mobile/core/widgets/loading_indicator.dart';
import 'package:baraqah_mobile/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/friend.dart';
import '../bloc/social_bloc.dart';
import '../bloc/social_event.dart';
import '../bloc/social_state.dart';

class FriendsPage extends StatelessWidget {
  static const String routeName = '/friends';
  const FriendsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SocialBloc>()..add(FetchFriendsRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: BlocBuilder<SocialBloc, SocialState>(
          builder: (context, state) {
            if (state is SocialLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is SocialFailure) {
              return Center(child: ErrorCard(message: state.message));
            }
            if (state is FriendsLoadSuccess) {
              return _FriendList(friends: state.friends);
            }
            return const Center(child: Text('No friends found.'));
          },
        ),
      ),
    );
  }
}

class _FriendList extends StatelessWidget {
  final List<Friend> friends;
  const _FriendList({Key? key, required this.friends}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(friend.name),
            subtitle: Text('${friend.mutualSessions} shared sessions'),
            trailing: Text('${friend.score} pts'),
          ),
        );
      },
    );
  }
}
