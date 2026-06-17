import 'package:baraqah_mobile/core/constants/api_endpoints.dart';
import 'package:baraqah_mobile/core/network/api_client.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  Future<TokenModel> login(String email, String password) async {
    // backend expects phone_number and password for login
    final response = await apiClient.post(ApiEndpoints.login,
        data: {'phone_number': email, 'password': password});
    return TokenModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<TokenModel> register(
      String name, String email, String password, String phone) async {
    // backend validation expects phone_number and full_name
    final response = await apiClient.post(ApiEndpoints.register, data: {
      'full_name': name,
      'email': email,
      'password': password,
      'phone_number': phone
    });
    return TokenModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<UserModel> fetchProfile() async {
    final response = await apiClient.get(ApiEndpoints.profile);
    return UserModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
