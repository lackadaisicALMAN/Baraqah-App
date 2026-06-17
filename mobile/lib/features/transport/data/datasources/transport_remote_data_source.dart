import 'package:baraqah_mobile/core/constants/api_endpoints.dart';
import 'package:baraqah_mobile/core/network/api_client.dart';
import '../models/carpool_model.dart';

class TransportRemoteDataSource {
  final ApiClient apiClient;
  TransportRemoteDataSource({required this.apiClient});

  Future<List<CarpoolModel>> fetchCarpools() async {
    final response = await apiClient.get(ApiEndpoints.transport);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => CarpoolModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> pickSeat(String carpoolId, int seatNumber) async {
    await apiClient.post('${ApiEndpoints.transport}/$carpoolId/pick',
        data: {'seatNumber': seatNumber});
  }
}
