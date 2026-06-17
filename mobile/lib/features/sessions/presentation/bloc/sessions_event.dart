import 'package:equatable/equatable.dart';

abstract class SessionsEvent extends Equatable {
  const SessionsEvent();

  @override
  List<Object?> get props => [];
}

class FetchSessionsRequested extends SessionsEvent {}

class CreateSessionRequested extends SessionsEvent {
  final String restaurantId;
  final String restaurantName;
  final String restaurantLocation;
  final DateTime scheduledAt;
  final int maxAttendees;
  final String foodCategory;
  final String splitType;         // 'EQUAL' | 'HOST_PAYS' | 'PERCENTAGE'
  final List<dynamic> splitDetails;
  final bool hasRideAvailable;
  final int availableRideSeats;
  final String hostTransportMode; // 'RIDE_TOGETHER' | 'MEET_THERE'
  final int rangeKm;              // 10 or 30

  const CreateSessionRequested({
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantLocation,
    required this.scheduledAt,
    required this.maxAttendees,
    required this.foodCategory,
    required this.splitType,
    this.splitDetails = const [],
    required this.hasRideAvailable,
    this.availableRideSeats = 0,
    required this.hostTransportMode,
    required this.rangeKm,
  });

  @override
  List<Object?> get props => [
        restaurantId,
        scheduledAt,
        maxAttendees,
        foodCategory,
        splitType,
        hasRideAvailable,
        hostTransportMode,
        rangeKm,
      ];
}

class JoinSessionRequested extends SessionsEvent {
  final String id;
  const JoinSessionRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class GetSessionDetailsRequested extends SessionsEvent {
  final String id;
  const GetSessionDetailsRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class FetchMySessionsRequested extends SessionsEvent {}
