import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/token_store.dart';

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$registerEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _saveTokensFromResponse(data);
      return;
    }

    throw Exception(_readError(response.body));
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$loginEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _saveTokensFromResponse(data);
      return;
    }

    throw Exception(_readError(response.body));
  }

  Future<Map<String, dynamic>> getProfile() async {
    final accessToken = TokenStore.instance.accessToken;
    if (accessToken == null) {
      throw Exception('No access token. Please log in again.');
    }

    var response = await _client.get(
      Uri.parse('$baseUrl$meEndpoint'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      await refreshAccessToken();
      final refreshedAccess = TokenStore.instance.accessToken;
      if (refreshedAccess == null) {
        throw Exception('Session expired. Please log in again.');
      }

      response = await _client.get(
        Uri.parse('$baseUrl$meEndpoint'),
        headers: {'Authorization': 'Bearer $refreshedAccess'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    }

    throw Exception(_readError(response.body));
  }

  Future<void> refreshAccessToken() async {
    final refreshToken = TokenStore.instance.refreshToken;
    if (refreshToken == null) {
      throw Exception('Missing refresh token. Please log in again.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl$refreshEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = data['access'] as String?;
      if (access == null || access.isEmpty) {
        throw Exception('Refresh response missing access token.');
      }
      TokenStore.instance.saveTokens(access: access, refresh: refreshToken);
      return;
    }

    throw Exception(_readError(response.body));
  }

  void _saveTokensFromResponse(Map<String, dynamic> data) {
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;

    if (access == null || refresh == null) {
      throw Exception('Missing tokens in response.');
    }

    TokenStore.instance.saveTokens(access: access, refresh: refresh);
  }

  String _readError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded.containsKey('detail')) {
        return decoded['detail'].toString();
      }
      if (decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
      return decoded.values.first.toString();
    } catch (_) {
      return 'Request failed.';
    }
  }
}
