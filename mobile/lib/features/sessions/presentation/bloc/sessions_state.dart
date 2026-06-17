import 'package:equatable/equatable.dart';
import '../../domain/entities/session.dart';

abstract class SessionsState extends Equatable {
  const SessionsState();

  @override
  List<Object?> get props => [];
}

class SessionsInitial extends SessionsState {}

class SessionsLoading extends SessionsState {}

class SessionsLoadSuccess extends SessionsState {
  final List<Session> sessions;
  const SessionsLoadSuccess(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class SessionCreateSuccess extends SessionsState {
  final Session session;
  const SessionCreateSuccess(this.session);

  @override
  List<Object?> get props => [session];
}

class SessionDetailsLoadSuccess extends SessionsState {
  final Session session;
  const SessionDetailsLoadSuccess(this.session);

  @override
  List<Object?> get props => [session];
}

class SessionsFailure extends SessionsState {
  final String message;
  const SessionsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class MySessionsLoadSuccess extends SessionsState {
  final List<Session> sessions;
  const MySessionsLoadSuccess(this.sessions);

  @override
  List<Object?> get props => [sessions];
}
