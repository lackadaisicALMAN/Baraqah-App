import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:baraqah_mobile/core/widgets/app_button.dart';
import 'package:baraqah_mobile/core/widgets/app_input.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/auth_state.dart';
import '../../../sessions/presentation/pages/sessions_list_page.dart';

class ProfileSetupPage extends StatefulWidget {
  static const String routeName = '/profileSetup';
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              Navigator.pushReplacementNamed(
                  context, SessionsListPage.routeName);
            }
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const SizedBox(height: 16),
                AppInput(label: 'Bio', controller: _bioController),
                const SizedBox(height: 16),
                AppInput(label: 'Location', controller: _locationController),
                const SizedBox(height: 24),
                AppButton(label: 'Finish Setup', onPressed: _finishSetup),
              ],
            );
          },
        ),
      ),
    );
  }

  void _finishSetup() {
    Navigator.pushReplacementNamed(context, SessionsListPage.routeName);
  }
}
