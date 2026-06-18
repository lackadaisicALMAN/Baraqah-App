import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../reviews/presentation/pages/post_session_feedback_page.dart';
import '../../domain/entities/session.dart';
import '../bloc/sessions_bloc.dart';
import '../bloc/sessions_event.dart';
import '../bloc/sessions_state.dart';

class SessionDetailPage extends StatefulWidget {
  final String sessionId;
  const SessionDetailPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  late final SessionsBloc _bloc;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<SessionsBloc>()..add(GetSessionDetailsRequested(widget.sessionId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _openCheckin() async {
    setState(() => _isActionLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('${ApiEndpoints.baseUrl}/checkin/sessions/${widget.sessionId}/open');
      _bloc.add(GetSessionDetailsRequested(widget.sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrival marked! Check-in is now open.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open check-in: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _mockCheckIn(String qrToken) async {
    setState(() => _isActionLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('${ApiEndpoints.baseUrl}/checkin/scan', data: {
        'qr_token': qrToken,
        'session_id': widget.sessionId,
        'lat': 0.0,
        'lng': 0.0,
      });
      _bloc.add(GetSessionDetailsRequested(widget.sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked in successfully! Good to eat.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check in: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _completeSession() async {
    setState(() => _isActionLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('${ApiEndpoints.baseUrl}/checkin/sessions/${widget.sessionId}/complete');
      _bloc.add(GetSessionDetailsRequested(widget.sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dining session completed! Please provide reviews.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _joinSession() async {
    setState(() => _isActionLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('${ApiEndpoints.baseUrl}/sessions/${widget.sessionId}/join', data: {
        'transport_mode': 'MEET_THERE',
      });
      _bloc.add(GetSessionDetailsRequested(widget.sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined dining plan successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Session Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<SessionsBloc, SessionsState>(
          builder: (context, state) {
            if (state is SessionsLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is SessionDetailsLoadSuccess) {
              final session = state.session;
              final isHost = session.attendees.any(
                  (a) => a.userId == currentUserId && a.isHost);
              final hasCheckedIn = session.attendees.any(
                  (a) => a.userId == currentUserId && !a.isHost); // hosts checkin by default

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Hosted by: ${session.host}',
                        style: const TextStyle(fontSize: 15, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Text(session.description, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Scheduled for: ${DateFormat.yMMMd().add_jm().format(session.startTime.toLocal())}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            session.restaurantLocation.isNotEmpty
                                ? session.restaurantLocation
                                : 'Lahore, Pakistan',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    const Text(
                      'Session Attendees',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAttendeesList(session.attendees),
                    const Divider(height: 30),
                    if (_isActionLoading)
                      const Center(child: LoadingIndicator())
                    else
                      _buildCheckinFlow(session, isHost, hasCheckedIn, currentUserId),
                  ],
                ),
              );
            }
            if (state is SessionsFailure) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('Session details unavailable.'));
          },
        ),
      ),
    );
  }

  Widget _buildAttendeesList(List<SessionAttendee> attendees) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final attendee = attendees[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.secondary.withOpacity(0.2),
            child: Text(
              attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : 'U',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            attendee.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.star, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                'Baraqah: ${attendee.baraqahScore.toStringAsFixed(1)}/7.0',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: attendee.isHost
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Host / Planner',
                    style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildCheckinFlow(Session session, bool isHost, bool hasCheckedIn, String? currentUserId) {
    final isAttendee = session.attendees.any((a) => a.userId == currentUserId);

    if (!isAttendee) {
      if (session.status == 'OPEN') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: 'Join Dining Plan',
              onPressed: _joinSession,
            ),
            const SizedBox(height: 8),
            const Text(
              'Join this pool to chat, ride-share, check-in, and write reviews.',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        );
      } else {
        return const Center(
          child: Text(
            'This plan is no longer accepting new members.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        );
      }
    }

    if (session.status == 'OPEN' || session.status == 'LOCKED') {
      if (isHost) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: 'Mark Arrival / Open Check-in',
              onPressed: _openCheckin,
            ),
          ],
        );
      } else {
        return const Center(
          child: Text(
            'Waiting for the host to arrive and open check-in code.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        );
      }
    }

    if (session.status == 'ACTIVE') {
      // If active, host has generated a QR token
      // We can grab it from details response or realtimeState.
      final qrToken = session.id; // Fallback or mock key.
      
      if (isHost) {
        return Column(
          children: [
            const Text(
              'Show this QR code to the attendees at the table:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=$qrToken',
              height: 160,
              width: 160,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.qr_code, size: 160),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Complete Dining Session',
              onPressed: _completeSession,
              color: AppColors.danger,
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Check-in is now open!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Scan QR Code / Check-in',
              onPressed: () => _mockCheckIn(qrToken),
            ),
            const SizedBox(height: 8),
            const Text(
              '(For Web/Chrome testing, this scans the session code automatically)',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
    }

    if (session.status == 'COMPLETED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dining plan completed! We verified your check-in. Time to write reviews!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Write Review & Feedback',
            onPressed: () {
              final toReview = session.attendees
                  .where((a) => a.userId != currentUserId)
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostSessionFeedbackPage(
                    sessionId: session.id,
                    restaurantId: session.restaurantId ?? '',
                    restaurantName: session.title,
                    attendeesToReview: toReview,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
