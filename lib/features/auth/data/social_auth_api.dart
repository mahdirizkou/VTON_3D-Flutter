import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';

class SocialAuthApi {
  SocialAuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> googleLogin({
    String? idToken,
    String? accessToken,
  }) async {
    late final Map<String, String> payload;
    if (idToken != null && idToken.isNotEmpty) {
      payload = {'id_token': idToken};
    } else if (accessToken != null && accessToken.isNotEmpty) {
      payload = {'access_token': accessToken};
    } else {
      throw Exception('Could not get Google token.');
    }

    final response = await _client.post(
      Uri.parse('$kBaseUrl/api/auth/social/google/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final data = _decodeMap(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return data;
    }

    throw Exception(_readError(data));
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  String _readError(Map<String, dynamic> data) {
    if (data.containsKey('detail')) {
      return data['detail'].toString();
    }
    if (data.containsKey('message')) {
      return data['message'].toString();
    }
    if (data.isNotEmpty) {
      final first = data.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
      return first.toString();
    }
    return 'Google login failed.';
  }
}
