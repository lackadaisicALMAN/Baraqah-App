import 'package:equatable/equatable.dart';

class Carpool extends Equatable {
  final String id;
  final String driverName;
  final int availableSeats;
  final String pickup;
  final String dropoff;

  const Carpool(
      {required this.id,
      required this.driverName,
      required this.availableSeats,
      required this.pickup,
      required this.dropoff});

  @override
  List<Object?> get props => [id, driverName, availableSeats, pickup, dropoff];
}
