import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/local_db.dart';
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_current_user_use_case.dart';
import '../features/auth/domain/usecases/login_use_case.dart';
import '../features/auth/domain/usecases/logout_use_case.dart';
import '../features/auth/domain/usecases/register_use_case.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/chat/data/datasources/chat_remote_data_source.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/fetch_chat_messages_use_case.dart';
import '../features/chat/domain/usecases/join_room_use_case.dart';
import '../features/chat/domain/usecases/send_message_use_case.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/reviews/data/datasources/reviews_remote_data_source.dart';
import '../features/reviews/data/repositories/reviews_repository_impl.dart';
import '../features/reviews/domain/repositories/reviews_repository.dart';
import '../features/reviews/domain/usecases/submit_review_use_case.dart';
import '../features/reviews/domain/usecases/fetch_recent_reviews_use_case.dart';
import '../features/reviews/domain/usecases/submit_user_review_use_case.dart';
import '../features/reviews/presentation/bloc/reviews_bloc.dart';
import '../features/social/data/datasources/social_remote_data_source.dart';
import '../features/social/data/repositories/social_repository_impl.dart';
import '../features/social/domain/repositories/social_repository.dart';
import '../features/social/domain/usecases/fetch_friends_use_case.dart';
import '../features/social/domain/usecases/fetch_leaderboard_use_case.dart';
import '../features/social/presentation/bloc/social_bloc.dart';
import '../features/sessions/data/datasources/sessions_remote_data_source.dart';
import '../features/sessions/data/repositories/sessions_repository_impl.dart';
import '../features/sessions/domain/repositories/sessions_repository.dart';
import '../features/sessions/domain/usecases/create_session_use_case.dart';
import '../features/sessions/domain/usecases/fetch_sessions_use_case.dart';
import '../features/sessions/domain/usecases/get_session_details_use_case.dart';
import '../features/sessions/domain/usecases/join_session_use_case.dart';
import '../features/sessions/domain/usecases/fetch_my_sessions_use_case.dart';
import '../features/sessions/presentation/bloc/sessions_bloc.dart';
import '../features/transport/data/datasources/transport_remote_data_source.dart';
import '../features/transport/data/repositories/transport_repository_impl.dart';
import '../features/transport/domain/repositories/transport_repository.dart';
import '../features/transport/domain/usecases/fetch_carpools_use_case.dart';
import '../features/transport/domain/usecases/pick_seat_use_case.dart';
import '../features/transport/presentation/bloc/transport_bloc.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  await Hive.initFlutter();
  final localDb = LocalDb();
  await localDb.init();
  final secureStorage = SecureStorage();
  final authInterceptor = AuthInterceptor(secureStorage: secureStorage);
  final apiClient = ApiClient(authInterceptor: authInterceptor);

  getIt.registerSingleton<SecureStorage>(secureStorage);
  getIt.registerSingleton<LocalDb>(localDb);
  getIt.registerSingleton<ApiClient>(apiClient);
  getIt.registerSingleton<AuthInterceptor>(authInterceptor);

  getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(apiClient: apiClient));
  getIt.registerLazySingleton<AuthLocalDataSource>(() =>
      AuthLocalDataSource(secureStorage: secureStorage, localDb: localDb));
  getIt.registerLazySingleton<AuthRepository>(() =>
      AuthRepositoryImpl(remoteDataSource: getIt(), localDataSource: getIt()));
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt()));
  getIt.registerFactory(() => AuthBloc(
      loginUseCase: getIt(),
      registerUseCase: getIt(),
      logoutUseCase: getIt(),
      getCurrentUserUseCase: getIt()));

  getIt.registerLazySingleton<SessionsRemoteDataSource>(
      () => SessionsRemoteDataSource(apiClient: apiClient));
  getIt.registerLazySingleton<SessionsRepository>(
      () => SessionsRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<FetchSessionsUseCase>(
      () => FetchSessionsUseCase(getIt()));
  getIt.registerLazySingleton<CreateSessionUseCase>(
      () => CreateSessionUseCase(getIt()));
  getIt.registerLazySingleton<JoinSessionUseCase>(
      () => JoinSessionUseCase(getIt()));
  getIt.registerLazySingleton<GetSessionDetailsUseCase>(
      () => GetSessionDetailsUseCase(getIt()));
  getIt.registerLazySingleton<FetchMySessionsUseCase>(
      () => FetchMySessionsUseCase(getIt()));
  getIt.registerFactory(() => SessionsBloc(
      fetchSessionsUseCase: getIt(),
      createSessionUseCase: getIt(),
      joinSessionUseCase: getIt(),
      getSessionDetailsUseCase: getIt(),
      fetchMySessionsUseCase: getIt()));

  getIt.registerLazySingleton<TransportRemoteDataSource>(
      () => TransportRemoteDataSource(apiClient: apiClient));
  getIt.registerLazySingleton<TransportRepository>(
      () => TransportRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<FetchCarpoolsUseCase>(
      () => FetchCarpoolsUseCase(getIt()));
  getIt.registerLazySingleton<PickSeatUseCase>(() => PickSeatUseCase(getIt()));
  getIt.registerFactory(() =>
      TransportBloc(fetchCarpoolsUseCase: getIt(), pickSeatUseCase: getIt()));

  getIt.registerLazySingleton<ReviewsRemoteDataSource>(
      () => ReviewsRemoteDataSource(apiClient: apiClient));
  getIt.registerLazySingleton<ReviewsRepository>(
      () => ReviewsRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<SubmitReviewUseCase>(
      () => SubmitReviewUseCase(getIt()));
  getIt.registerLazySingleton<FetchRecentReviewsUseCase>(
      () => FetchRecentReviewsUseCase(getIt()));
  getIt.registerLazySingleton<SubmitUserReviewUseCase>(
      () => SubmitUserReviewUseCase(getIt()));
  getIt.registerFactory(() => ReviewsBloc(
        submitReviewUseCase: getIt(),
        fetchRecentReviewsUseCase: getIt(),
        submitUserReviewUseCase: getIt(),
      ));

  getIt.registerLazySingleton<SocialRemoteDataSource>(
      () => SocialRemoteDataSource(apiClient: apiClient));
  getIt.registerLazySingleton<SocialRepository>(
      () => SocialRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<FetchFriendsUseCase>(
      () => FetchFriendsUseCase(getIt()));
  getIt.registerLazySingleton<FetchLeaderboardUseCase>(
      () => FetchLeaderboardUseCase(getIt()));
  getIt.registerFactory(() => SocialBloc(
      fetchFriendsUseCase: getIt(), fetchLeaderboardUseCase: getIt()));

  getIt.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSource(secureStorage: secureStorage));
  getIt.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<FetchChatMessagesUseCase>(
      () => FetchChatMessagesUseCase(getIt()));
  getIt.registerLazySingleton<JoinRoomUseCase>(() => JoinRoomUseCase(getIt()));
  getIt.registerLazySingleton<SendMessageUseCase>(
      () => SendMessageUseCase(getIt()));
  getIt.registerFactory(() => ChatBloc(
      fetchChatMessagesUseCase: getIt(),
      joinRoomUseCase: getIt(),
      sendMessageUseCase: getIt()));
}
