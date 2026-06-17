import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/fetch_carpools_use_case.dart';
import '../../domain/usecases/pick_seat_use_case.dart';
import 'transport_event.dart';
import 'transport_state.dart';

class TransportBloc extends Bloc<TransportEvent, TransportState> {
  final FetchCarpoolsUseCase fetchCarpoolsUseCase;
  final PickSeatUseCase pickSeatUseCase;

  TransportBloc(
      {required this.fetchCarpoolsUseCase, required this.pickSeatUseCase})
      : super(TransportInitial()) {
    on<FetchCarpoolsRequested>(_onFetchCarpools);
    on<PickSeatRequested>(_onPickSeat);
  }

  Future<void> _onFetchCarpools(
      FetchCarpoolsRequested event, Emitter<TransportState> emit) async {
    emit(TransportLoading());
    try {
      final carpools = await fetchCarpoolsUseCase.call();
      emit(TransportLoadSuccess(carpools));
    } catch (error) {
      emit(TransportFailure(error.toString()));
    }
  }

  Future<void> _onPickSeat(
      PickSeatRequested event, Emitter<TransportState> emit) async {
    emit(TransportLoading());
    try {
      await pickSeatUseCase.call(event.carpoolId, event.seatNumber);
      emit(SeatPickSuccess(event.carpoolId));
      add(FetchCarpoolsRequested());
    } catch (error) {
      emit(TransportFailure(error.toString()));
    }
  }
}
