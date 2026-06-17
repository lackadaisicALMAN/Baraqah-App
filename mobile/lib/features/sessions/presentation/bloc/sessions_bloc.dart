import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_session_use_case.dart';
import '../../domain/usecases/fetch_sessions_use_case.dart';
import '../../domain/usecases/get_session_details_use_case.dart';
import '../../domain/usecases/join_session_use_case.dart';
import '../../domain/usecases/fetch_my_sessions_use_case.dart';
import 'sessions_event.dart';
import 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final FetchSessionsUseCase fetchSessionsUseCase;
  final CreateSessionUseCase createSessionUseCase;
  final JoinSessionUseCase joinSessionUseCase;
  final GetSessionDetailsUseCase getSessionDetailsUseCase;
  final FetchMySessionsUseCase fetchMySessionsUseCase;

  SessionsBloc({
    required this.fetchSessionsUseCase,
    required this.createSessionUseCase,
    required this.joinSessionUseCase,
    required this.getSessionDetailsUseCase,
    required this.fetchMySessionsUseCase,
  }) : super(SessionsInitial()) {
    on<FetchSessionsRequested>(_fetchSessions);
    on<CreateSessionRequested>(_createSession);
    on<JoinSessionRequested>(_joinSession);
    on<GetSessionDetailsRequested>(_getSessionDetails);
    on<FetchMySessionsRequested>(_fetchMySessions);
  }

  Future<void> _fetchSessions(
      FetchSessionsRequested event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    try {
      final sessions = await fetchSessionsUseCase.call();
      emit(SessionsLoadSuccess(sessions));
    } catch (error) {
      emit(SessionsFailure(error.toString()));
    }
  }

  Future<void> _createSession(
      CreateSessionRequested event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    try {
      final session = await createSessionUseCase.call(
        restaurantId: event.restaurantId,
        restaurantName: event.restaurantName,
        restaurantLocation: event.restaurantLocation,
        scheduledAt: event.scheduledAt,
        maxAttendees: event.maxAttendees,
        foodCategory: event.foodCategory,
        splitType: event.splitType,
        splitDetails: event.splitDetails,
        hasRideAvailable: event.hasRideAvailable,
        availableRideSeats: event.availableRideSeats,
        hostTransportMode: event.hostTransportMode,
      );
      emit(SessionCreateSuccess(session));
    } catch (error) {
      emit(SessionsFailure(error.toString()));
    }
  }

  Future<void> _joinSession(
      JoinSessionRequested event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    try {
      await joinSessionUseCase.call(event.id);
      emit(const SessionsLoadSuccess([]));
      add(FetchSessionsRequested());
    } catch (error) {
      emit(SessionsFailure(error.toString()));
    }
  }

  Future<void> _getSessionDetails(
      GetSessionDetailsRequested event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    try {
      final session = await getSessionDetailsUseCase.call(event.id);
      emit(SessionDetailsLoadSuccess(session));
    } catch (error) {
      emit(SessionsFailure(error.toString()));
    }
  }

  Future<void> _fetchMySessions(
      FetchMySessionsRequested event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    try {
      final sessions = await fetchMySessionsUseCase.call();
      emit(MySessionsLoadSuccess(sessions));
    } catch (error) {
      emit(SessionsFailure(error.toString()));
    }
  }
}
