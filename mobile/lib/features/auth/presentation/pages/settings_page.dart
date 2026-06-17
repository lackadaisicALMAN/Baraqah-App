import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../di/injection.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/presentation/bloc/sessions_bloc.dart';
import '../../../sessions/presentation/bloc/sessions_event.dart';
import '../../../sessions/presentation/bloc/sessions_state.dart';
import '../../data/models/user_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class SettingsPage extends StatefulWidget {
  static const String routeName = '/settings';
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserModel? _userProfile;
  bool _isLoadingProfile = false;
  final List<Map<String, String>> _mockCards = [
    {'brand': 'Visa', 'last4': '4242'},
    {'brand': 'Mastercard', 'last4': '8888'},
  ];
  double _walletBalance = 125.50;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get(ApiEndpoints.profile);
      if (mounted) {
        setState(() {
          _userProfile =
              UserModel.fromJson(Map<String, dynamic>.from(response.data as Map));
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _updateProfile(String name, String bio) async {
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.patch(ApiEndpoints.profile, data: {
        'full_name': name,
        'bio': bio,
      });
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _showEditProfileDialog() {
    if (_userProfile == null) return;
    final nameController = TextEditingController(text: _userProfile!.name);
    final bioController = TextEditingController(text: _userProfile!.bio ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateProfile(nameController.text, bioController.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCardDialog() {
    final numberController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Payment Method'),
          content: TextField(
            controller: numberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: 'XXXX XXXX XXXX XXXX',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (numberController.text.length >= 4) {
                  setState(() {
                    _mockCards.add({
                      'brand': 'Visa',
                      'last4': numberController.text
                          .substring(numberController.text.length - 4),
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SessionsBloc>()..add(FetchMySessionsRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Baraqah Account Settings'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
          ],
        ),
        body: _isLoadingProfile || _userProfile == null
            ? const Center(child: LoadingIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 20),
                    _buildBaraqahMeterSection(),
                    const SizedBox(height: 20),
                    _buildWalletSection(),
                    const SizedBox(height: 20),
                    _buildPaymentMethodsSection(),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Recent Sessions Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRecentSessionsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.secondary,
              child: Text(
                _userProfile!.name.isNotEmpty
                    ? _userProfile!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userProfile!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_userProfile!.email,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(_userProfile!.phone,
                      style: const TextStyle(color: Colors.grey)),
                  if (_userProfile!.bio != null &&
                      _userProfile!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _userProfile!.bio!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: _showEditProfileDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaraqahMeterSection() {
    final score = _userProfile!.baraqahScore;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Baraqah Integrity Score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: score / 7.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 5.0
                          ? Colors.green
                          : (score >= 3.0 ? Colors.orange : Colors.red),
                    ),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${score.toStringAsFixed(1)} / 7.0 Stars',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep your score high by attending your foodpool plans on time. Missing plans without notice drops 1 star.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.primary,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Baraqah Wallet Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                setState(() {
                  _walletBalance += 50.00;
                });
              },
              child: const Text('Top Up'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Methods',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _showAddCardDialog,
                  child: const Text('Add Card'),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockCards.length,
              itemBuilder: (context, index) {
                final card = _mockCards[index];
                return ListTile(
                  leading:
                      const Icon(Icons.credit_card, color: AppColors.secondary),
                  title: Text('${card['brand']} ending in ${card['last4']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _mockCards.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessionsSection() {
    return BlocBuilder<SessionsBloc, SessionsState>(
      builder: (context, state) {
        if (state is SessionsLoading) {
          return const Center(child: LoadingIndicator());
        }
        if (state is SessionsFailure) {
          return Center(
            child: Text(
              'Failed to load sessions: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (state is MySessionsLoadSuccess) {
          final sessions = state.sessions;
          if (sessions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text('No sessions logged yet. Create or join one!'),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final dateStr =
                  DateFormat.yMMMd().format(session.startTime.toLocal());
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    session.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Hosted by ${session.host} • $dateStr',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Completed',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
