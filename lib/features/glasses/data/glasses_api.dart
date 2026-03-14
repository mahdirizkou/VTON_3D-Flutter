import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/glasses_item.dart';

class GlassesApi {
  const GlassesApi();

  Future<List<GlassesItem>> fetchGlasses() async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/glasses/');
    final http.Response response = await http.get(uri);
    _throwIfRequestFailed(response);

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> listPayload;

    if (decoded is List) {
      listPayload = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final dynamic nested = decoded['results'] ?? decoded['data'] ?? decoded['items'];
      if (nested is List) {
        listPayload = nested;
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Unexpected response format');
    }

    return listPayload
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) => GlassesItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<GlassesItem> fetchGlassesDetail(int id) async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/glasses/$id/');
    final http.Response response = await http.get(uri);
    _throwIfRequestFailed(response);

    final dynamic decoded = jsonDecode(response.body);
    final Map<String, dynamic> payload = _extractObjectPayload(decoded);
    return GlassesItem.fromJson(payload);
  }

  Future<GlassesItem> fetchTryOnPayload(GlassesItem item) async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/glasses/${item.id}/tryon/');
    final http.Response response = await http.get(uri);
    _throwIfRequestFailed(response);

    final dynamic decoded = jsonDecode(response.body);
    final Map<String, dynamic> payload = _extractObjectPayload(decoded);
    return item.mergeWith(GlassesItem.fromJson(payload));
  }

  void _throwIfRequestFailed(http.Response response) {
    if (response.statusCode == 401) {
      throw const ApiUnauthorizedException('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  Map<String, dynamic> _extractObjectPayload(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final dynamic nested = decoded['data'] ?? decoded['item'] ?? decoded['glasses'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return decoded;
    }

    throw Exception('Unexpected response format');
  }
}
