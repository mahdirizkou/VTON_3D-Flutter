import '../../../core/utils/parsers.dart';
import 'vec3.dart';

class GlassesItem {
  const GlassesItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.thumbnailUrl,
    required this.price,
    required this.rating,
    required this.tags,
    this.glbUrl,
    this.scale,
    this.positionOffset,
    this.rotationOffset,
    this.anchor,
    this.version,
  });

  factory GlassesItem.fromJson(Map<String, dynamic> json) {
    final dynamic tagsRaw = json['tags'];
    final List<String> parsedTags = tagsRaw is List
        ? tagsRaw
            .map((e) {
              if (e is String) return e;
              if (e is Map<String, dynamic>) {
                if (e['name'] != null) return e['name'].toString();
                if (e['label'] != null) return e['label'].toString();
              }
              return e.toString();
            })
            .where((tag) => tag.trim().isNotEmpty)
            .toList()
        : <String>[];

    return GlassesItem(
      id: parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? 'Unnamed',
      brand: json['brand']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      price: parseDouble(json['price']) ?? 0,
      rating: parseDouble(json['rating']),
      tags: parsedTags,
    );
  }

  final int id;
  final String name;
  final String? brand;
  final String? thumbnailUrl;
  final double price;
  final double? rating;
  final List<String> tags;

  final String? glbUrl;
  final double? scale;
  final Vec3? positionOffset;
  final Vec3? rotationOffset;
  final String? anchor;
  final String? version;

  GlassesItem copyWith({
    String? glbUrl,
    double? scale,
    Vec3? positionOffset,
    Vec3? rotationOffset,
    String? anchor,
    String? version,
  }) {
    return GlassesItem(
      id: id,
      name: name,
      brand: brand,
      thumbnailUrl: thumbnailUrl,
      price: price,
      rating: rating,
      tags: tags,
      glbUrl: glbUrl ?? this.glbUrl,
      scale: scale ?? this.scale,
      positionOffset: positionOffset ?? this.positionOffset,
      rotationOffset: rotationOffset ?? this.rotationOffset,
      anchor: anchor ?? this.anchor,
      version: version ?? this.version,
    );
  }
}
