import 'package:equatable/equatable.dart';

abstract class TransportEvent extends Equatable {
  const TransportEvent();

  @override
  List<Object?> get props => [];
}

class FetchCarpoolsRequested extends TransportEvent {}

class PickSeatRequested extends TransportEvent {
  final String carpoolId;
  final int seatNumber;

  const PickSeatRequested({required this.carpoolId, required this.seatNumber});

  @override
  List<Object?> get props => [carpoolId, seatNumber];
}
