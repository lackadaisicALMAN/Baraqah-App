import '../../domain/entities/carpool.dart';

class CarpoolModel extends Carpool {
  const CarpoolModel(
      {required String id,
      required String driverName,
      required int availableSeats,
      required String pickup,
      required String dropoff})
      : super(
            id: id,
            driverName: driverName,
            availableSeats: availableSeats,
            pickup: pickup,
            dropoff: dropoff);

  factory CarpoolModel.fromJson(Map<String, dynamic> json) {
    return CarpoolModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      driverName: json['driverName'] ?? json['driver'] ?? 'Unknown',
      availableSeats: json['availableSeats'] ?? json['seats'] ?? 0,
      pickup: json['pickup'] ?? '',
      dropoff: json['dropoff'] ?? '',
    );
  }
}
