import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/glasses_item.dart';
import '../models/vec3.dart';
import '../../../core/utils/parsers.dart';

class GlassesApi {
  const GlassesApi();

  Future<List<GlassesItem>> fetchGlasses() async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/glasses/');
    final http.Response response = await http.get(uri);

    if (response.statusCode == 401) {
      throw const ApiUnauthorizedException('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GlassesItem.fromJson)
        .toList();
  }

  Future<GlassesItem> fetchTryOnPayload(GlassesItem item) async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/glasses/${item.id}/tryon/');
    final http.Response response = await http.get(uri);

    if (response.statusCode == 401) {
      throw const ApiUnauthorizedException('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format');
    }

    final dynamic positionRaw = decoded['position_offset'];
    final dynamic rotationRaw = decoded['rotation_offset'];

    return item.copyWith(
      glbUrl: decoded['glb_url']?.toString(),
      scale: parseDouble(decoded['scale']),
      positionOffset: positionRaw is Map<String, dynamic> ? Vec3.fromJson(positionRaw) : null,
      rotationOffset: rotationRaw is Map<String, dynamic> ? Vec3.fromJson(rotationRaw) : null,
      anchor: decoded['anchor']?.toString(),
      version: decoded['version']?.toString(),
    );
  }
}
