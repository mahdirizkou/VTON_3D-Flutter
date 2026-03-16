import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/constants.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/glasses_item.dart';
import '../models/tripo_generation_job.dart';

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

  Future<TripoGenerationJob> generateTripoModel({
    String? glassesId,
    required Uint8List frontImageBytes,
    required String frontImageName,
    Uint8List? leftImageBytes,
    String? leftImageName,
    Uint8List? backImageBytes,
    String? backImageName,
    Uint8List? rightImageBytes,
    String? rightImageName,
  }) async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/tripo/generate/');
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);

    // Only send glasses_id when it is a non-empty value so Django does not
    // receive an empty string for a PrimaryKeyRelatedField.
    if (glassesId != null && glassesId.trim().isNotEmpty) {
      request.fields['glasses_id'] = glassesId.trim();
    }

    // Front image is required — always include it with a proper content-type
    // so Django's ImageField validation passes (it rejects application/octet-stream).
    request.files.add(
      http.MultipartFile.fromBytes(
        'front_image',
        frontImageBytes,
        filename: _safeFileName(frontImageName),
        contentType: MediaType('image', _extensionToSubtype(frontImageName)),
      ),
    );

    _addOptionalImage(
      request: request,
      fieldName: 'left_image',
      bytes: leftImageBytes,
      fileName: leftImageName,
    );
    _addOptionalImage(
      request: request,
      fieldName: 'back_image',
      bytes: backImageBytes,
      fileName: backImageName,
    );
    _addOptionalImage(
      request: request,
      fieldName: 'right_image',
      bytes: rightImageBytes,
      fileName: rightImageName,
    );

    final http.StreamedResponse streamedResponse = await request.send();
    final http.Response response = await http.Response.fromStream(streamedResponse);
    _throwIfRequestFailed(response);

    final dynamic decoded = jsonDecode(response.body);
    final Map<String, dynamic> raw =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    // The creation endpoint returns {job_id, task_id, status} — normalise the
    // key names to match what TripoGenerationJob.fromJson() expects.
    final Map<String, dynamic> normalized = <String, dynamic>{
      'id': raw['job_id'] ?? raw['id'],
      'task_id': raw['task_id'] ?? '',
      'status': raw['status'] ?? 'processing',
      'model_url': raw['model_url'],
      'error_message': raw['error_message'] ?? '',
    };
    return TripoGenerationJob.fromJson(normalized);
  }

  Future<TripoGenerationJob> fetchTripoJobStatus(int jobId) async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/tripo/jobs/$jobId/status/');
    final http.Response response = await http.get(uri);
    _throwIfRequestFailed(response);

    final dynamic decoded = jsonDecode(response.body);
    final Map<String, dynamic> raw =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    // Status endpoint returns {job_id, task_id, status, model_url, error_message}.
    // Normalise job_id → id so fromJson() finds the right key.
    final Map<String, dynamic> normalized = <String, dynamic>{
      'id': raw['job_id'] ?? raw['id'],
      'task_id': raw['task_id'] ?? '',
      'status': raw['status'] ?? '',
      'model_url': raw['model_url'],
      'error_message': raw['error_message'] ?? '',
    };
    return TripoGenerationJob.fromJson(normalized);
  }

  Future<List<TripoGenerationJob>> fetchTripoJobs() async {
    final Uri uri = Uri.parse('$kBaseUrl/api/glasses2/tripo/jobs/');
    final http.Response response = await http.get(uri);
    _throwIfRequestFailed(response);

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> listPayload = _extractListPayload(decoded);

    return listPayload
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              TripoGenerationJob.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _addOptionalImage({
    required http.MultipartRequest request,
    required String fieldName,
    required Uint8List? bytes,
    required String? fileName,
  }) {
    if (bytes == null || bytes.isEmpty) return;
    final String name = fileName ?? '$fieldName.jpg';
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: _safeFileName(name),
        // Explicit content-type is required — without it the http package sends
        // application/octet-stream which Django's ImageField rejects with a 400.
        contentType: MediaType('image', _extensionToSubtype(name)),
      ),
    );
  }

  /// Extracts the basename and truncates to 90 characters so the full stored
  /// path stays under Django's ImageField max_length of 100.
  ///
  /// image_picker returns the full device path as the file name, e.g.:
  ///   /data/user/0/com.example.app/cache/image_picker/abc123_very_long.jpg
  /// That is 133 chars, which Django rejects with a 400 validation error.
  String _safeFileName(String rawName) {
    // Take only the last path segment (the actual file name).
    final String baseName = rawName.split('/').last.split('\\').last;

    // Split into stem and extension so we never cut through the extension.
    final int dotIndex = baseName.lastIndexOf('.');
    final String stem = dotIndex >= 0 ? baseName.substring(0, dotIndex) : baseName;
    final String ext = dotIndex >= 0 ? baseName.substring(dotIndex) : '';

    // Django stores files under upload_to + filename.
    // upload_to = "tripo/source_images/" = 20 chars.
    // Django's ImageField max_length = 100.
    // We budget 78 chars for the basename (100 - 20 - 2 safety margin).
    const int maxBaseName = 78;
    final int maxStem = maxBaseName - ext.length;
    final String safeStem = stem.length > maxStem ? stem.substring(0, maxStem) : stem;

    return '$safeStem$ext';
  }

  /// Maps a file name extension to the MIME subtype expected by Django.
  String _extensionToSubtype(String fileName) {
    final String ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg';
    }
  }

  void _throwIfRequestFailed(http.Response response) {
    if (response.statusCode == 401) {
      throw const ApiUnauthorizedException('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // ignore: avoid_print
      print('[GlassesApi] HTTP ${response.statusCode}: ${response.body}');
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
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

  List<dynamic> _extractListPayload(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final dynamic nested =
          decoded['results'] ?? decoded['data'] ?? decoded['items'] ?? decoded['jobs'];
      if (nested is List) {
        return nested;
      }
    }
    throw Exception('Unexpected response format');
  }
}