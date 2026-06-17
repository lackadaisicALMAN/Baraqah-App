import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baraqah_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:baraqah_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:baraqah_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/profile_setup_page.dart';
import 'features/sessions/presentation/pages/sessions_list_page.dart';
import 'features/social/presentation/pages/friends_page.dart';
import 'features/social/presentation/pages/leaderboard_page.dart';
import 'features/transport/presentation/pages/carpool_page.dart';
import 'features/reviews/presentation/pages/review_page.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/home/presentation/pages/main_navigation_page.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/widgets/loading_indicator.dart';
import 'di/injection.dart';

class BaraqahApp extends StatelessWidget {
  const BaraqahApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.outfitTextTheme(),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              textStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        routes: {
          LoginPage.routeName: (_) => const LoginPage(),
          RegisterPage.routeName: (_) => const RegisterPage(),
          ProfileSetupPage.routeName: (_) => const ProfileSetupPage(),
          SessionsListPage.routeName: (_) => const MainNavigationPage(),
          MainNavigationPage.routeName: (_) => const MainNavigationPage(),
          FriendsPage.routeName: (_) => const FriendsPage(),
          LeaderboardPage.routeName: (_) => const LeaderboardPage(),
          CarpoolPage.routeName: (_) => const CarpoolPage(),
          ReviewPage.routeName: (_) => const ReviewPage(),
          ChatPage.routeName: (_) => const ChatPage(),
        },
        home: const AuthEntryPoint(),
      ),
    );
  }
}

class AuthEntryPoint extends StatelessWidget {
  const AuthEntryPoint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }
        if (state is Authenticated) {
          return const MainNavigationPage();
        }
        return const LoginPage();
      },
    );
  }
}
