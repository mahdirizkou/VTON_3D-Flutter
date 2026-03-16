import '../../../core/utils/parsers.dart';

class TripoGenerationJob {
  const TripoGenerationJob({
    required this.jobId,
    required this.status,
    this.taskId,
    this.modelUrl,
    this.errorMessage,
    this.previewImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory TripoGenerationJob.fromJson(Map<String, dynamic> json) {
    return TripoGenerationJob(
      jobId: parseInt(_readFirst(json, const <String>['job_id', 'id'])) ?? 0,
      taskId: _readFirst(json, const <String>['task_id', 'taskId'])?.toString(),
      status: _readFirst(json, const <String>['status'])?.toString() ?? 'pending',
      modelUrl: _readFirst(json, const <String>['model_url', 'modelUrl'])?.toString(),
      errorMessage: _readFirst(json, const <String>['error_message', 'errorMessage'])?.toString(),
      previewImageUrl: _readFirst(
        json,
        const <String>['preview_image_url', 'previewImageUrl', 'thumbnail_url', 'thumbnail'],
      )?.toString(),
      createdAt: _parseDateTime(_readFirst(json, const <String>['created_at', 'createdAt'])),
      updatedAt: _parseDateTime(_readFirst(json, const <String>['updated_at', 'updatedAt'])),
    );
  }

  final int jobId;
  final String? taskId;
  final String status;
  final String? modelUrl;
  final String? errorMessage;
  final String? previewImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isTerminal => status == 'success' || status == 'failed';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get hasModelUrl => (modelUrl ?? '').trim().isNotEmpty;
  String get displayStatus {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  static dynamic _readFirst(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key];
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
