import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/errors/api_exceptions.dart';
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
      Uri.parse('$kBaseUrl$registerEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokensFromResponse(data);
      return;
    }

    throw Exception(_readError(response.body));
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$kBaseUrl$loginEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokensFromResponse(data);
      return;
    }

    throw Exception(_readError(response.body));
  }

  Future<Map<String, dynamic>> me() async {
    var accessToken = await TokenStore.instance.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiUnauthorizedException('No access token. Please log in again.');
    }

    var response = await _client.get(
      Uri.parse('$kBaseUrl$meEndpoint'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw const ApiUnauthorizedException('Session expired. Please log in again.');
      }

      accessToken = await TokenStore.instance.getAccessToken();
      response = await _client.get(
        Uri.parse('$kBaseUrl$meEndpoint'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw const ApiUnauthorizedException('Session expired. Please log in again.');
      }
    }

    throw Exception(_readError(response.body));
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await TokenStore.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final response = await _client.post(
      Uri.parse('$kBaseUrl$refreshEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = data['access'] as String?;
      if (access == null || access.isEmpty) {
        return false;
      }
      await TokenStore.instance.saveTokens(access: access, refresh: refreshToken);
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    await TokenStore.instance.clearTokens();
  }

  Future<void> _saveTokensFromResponse(Map<String, dynamic> data) async {
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;

    if (access == null || refresh == null || access.isEmpty || refresh.isEmpty) {
      throw Exception('Missing tokens in response.');
    }

    await TokenStore.instance.saveTokens(access: access, refresh: refresh);
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
      if (decoded.isNotEmpty) {
        return decoded.values.first.toString();
      }
    } catch (_) {}
    return 'Request failed.';
  }
}
