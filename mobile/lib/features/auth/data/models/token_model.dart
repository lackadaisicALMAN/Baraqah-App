import '../../domain/entities/token.dart';

class TokenModel extends Token {
  const TokenModel({required String accessToken, required String refreshToken})
      : super(accessToken: accessToken, refreshToken: refreshToken);

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    final data =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    return TokenModel(
      accessToken:
          data['accessToken'] ?? data['access_token'] ?? data['token'] ?? '',
      refreshToken: data['refreshToken'] ?? data['refresh_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken, 'refreshToken': refreshToken};
  }
}
