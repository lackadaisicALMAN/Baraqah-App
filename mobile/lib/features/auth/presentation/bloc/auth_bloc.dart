import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc(
      {required this.loginUseCase,
      required this.registerUseCase,
      required this.logoutUseCase,
      required this.getCurrentUserUseCase})
      : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await getCurrentUserUseCase.call();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (error) {
      // Log full error for debugging
      // ignore: avoid_print
      print('AuthStarted error: ${error.runtimeType} -- $error');
      try {
        // try to print stack if available
        // ignore: avoid_print
        print(error is Error ? (error.stackTrace) : 'no stacktrace');
      } catch (_) {}
      emit(AuthFailure(_mapError(error)));
    }
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await loginUseCase.call(event.email.trim(), event.password.trim());
      final user = await getCurrentUserUseCase.call();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (error) {
      // Log full error for debugging
      // ignore: avoid_print
      print('Login error: ${error.runtimeType} -- $error');
      try {
        // ignore: avoid_print
        print(error is Error ? (error.stackTrace) : 'no stacktrace');
      } catch (_) {}
      emit(AuthFailure(_mapError(error)));
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await registerUseCase.call(event.name.trim(), event.email.trim(),
          event.password.trim(), event.phone.trim());
      final user = await getCurrentUserUseCase.call();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (error) {
      // Log full error for debugging
      // ignore: avoid_print
      print('Register error: ${error.runtimeType} -- $error');
      try {
        // ignore: avoid_print
        print(error is Error ? (error.stackTrace) : 'no stacktrace');
      } catch (_) {}
      emit(AuthFailure(_mapError(error)));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await logoutUseCase.call();
      emit(Unauthenticated());
    } catch (error) {
      emit(AuthFailure(_mapError(error)));
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timed out. Please check your network and try again.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server. Check your internet connection.';
        case DioExceptionType.badResponse:
          final response = error.response;
          if (response != null && response.data != null) {
            final data = response.data;
            if (data is Map<String, dynamic>) {
              return data['message']?.toString() ??
                  data['error']?.toString() ??
                  'Authentication failed. Please verify your credentials.';
            }
            return data.toString();
          }
          return 'Authentication failed. Please verify your credentials.';
        case DioExceptionType.unknown:
          return 'Network error. Please try again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }

    if (error is String) {
      return error;
    }
    // Expose exception message when available to aid debugging
    if (error is Error || error is Exception) return error.toString();
    return 'An unexpected error occurred. Please try again.';
  }
}
