import 'package:equatable/equatable.dart';
import '../../domain/entities/carpool.dart';

abstract class TransportState extends Equatable {
  const TransportState();

  @override
  List<Object?> get props => [];
}

class TransportInitial extends TransportState {}

class TransportLoading extends TransportState {}

class TransportLoadSuccess extends TransportState {
  final List<Carpool> carpools;
  const TransportLoadSuccess(this.carpools);

  @override
  List<Object?> get props => [carpools];
}

class TransportFailure extends TransportState {
  final String message;
  const TransportFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class SeatPickSuccess extends TransportState {
  final String carpoolId;
  const SeatPickSuccess(this.carpoolId);

  @override
  List<Object?> get props => [carpoolId];
}
