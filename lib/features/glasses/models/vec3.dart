import '../../../core/utils/parsers.dart';

class Vec3 {
  const Vec3({required this.x, required this.y, required this.z});

  factory Vec3.fromJson(Map<String, dynamic> json) {
    return Vec3(
      x: parseDouble(json['x']) ?? 0,
      y: parseDouble(json['y']) ?? 0,
      z: parseDouble(json['z']) ?? 0,
    );
  }

  final double x;
  final double y;
  final double z;

  String toInlineString() =>
      'x=${x.toStringAsFixed(3)}, y=${y.toStringAsFixed(3)}, z=${z.toStringAsFixed(3)}';
}
