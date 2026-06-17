import 'package:equatable/equatable.dart';

class SessionAttendee extends Equatable {
  final String userId;
  final String name;
  final double baraqahScore;
  final bool isHost;
  final String transportMode;

  const SessionAttendee({
    required this.userId,
    required this.name,
    required this.baraqahScore,
    required this.isHost,
    required this.transportMode,
  });

  @override
  List<Object?> get props => [userId, name, baraqahScore, isHost, transportMode];
}

class Session extends Equatable {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String restaurantLocation;
  final DateTime startTime;
  final String host;
  final int availableSeats;
  final int capacity;
  final bool joined;
  final String status;
  final String? restaurantId;
  final List<SessionAttendee> attendees;

  const Session({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.restaurantLocation = '',
    required this.startTime,
    required this.host,
    required this.availableSeats,
    required this.capacity,
    this.joined = false,
    this.status = 'OPEN',
    this.restaurantId,
    this.attendees = const [],
  });

  @override
  List<Object?> get props => [
        id, title, description, latitude, longitude,
        restaurantLocation, startTime, host,
        availableSeats, capacity, joined, status,
        restaurantId, attendees,
      ];
}
