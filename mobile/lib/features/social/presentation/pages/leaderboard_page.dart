import 'package:baraqah_mobile/core/widgets/error_card.dart';
import 'package:baraqah_mobile/core/widgets/loading_indicator.dart';
import 'package:baraqah_mobile/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../bloc/social_bloc.dart';
import '../bloc/social_event.dart';
import '../bloc/social_state.dart';

class LeaderboardPage extends StatelessWidget {
  static const String routeName = '/leaderboard';
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SocialBloc>()..add(FetchLeaderboardRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Leaderboard')),
        body: BlocBuilder<SocialBloc, SocialState>(
          builder: (context, state) {
            if (state is SocialLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is SocialFailure) {
              return Center(child: ErrorCard(message: state.message));
            }
            if (state is LeaderboardLoadSuccess) {
              return _LeaderboardList(entries: state.entries);
            }
            return const Center(child: Text('Leaderboard not available.'));
          },
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _LeaderboardList({Key? key, required this.entries}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(child: Text(entry.rank.toString())),
            title: Text(entry.name),
            trailing: Text('${entry.score} pts'),
          ),
        );
      },
    );
  }
}
