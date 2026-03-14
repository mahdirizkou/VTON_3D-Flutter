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
    this.createdAt,
    this.updatedAt,
  });

  factory GlassesItem.fromJson(Map<String, dynamic> json) {
    final dynamic tagsRaw = _readFirst(json, <String>['tags', 'tag_list', 'categories']);

    return GlassesItem(
      id: parseInt(_readFirst(json, <String>['id', 'glasses_id'])) ?? 0,
      name: _readFirst(json, <String>['name', 'title'])?.toString() ?? 'Unnamed',
      brand: _readFirst(json, <String>['brand', 'brand_name'])?.toString(),
      thumbnailUrl: _readFirst(
        json,
        <String>['thumbnail_url', 'thumbnailUrl', 'thumbnail', 'image_url', 'image'],
      )?.toString(),
      price: parseDouble(_readFirst(json, <String>['price', 'unit_price'])) ?? 0,
      rating: parseDouble(_readFirst(json, <String>['rating', 'average_rating'])),
      tags: _parseTags(tagsRaw),
      glbUrl: _readFirst(
        json,
        <String>['modelGlb', 'model_glb', 'model_glb_url', 'glb_url', 'glbUrl', 'model_url'],
      )?.toString(),
      scale: parseDouble(_readFirst(json, <String>['scale'])),
      positionOffset: _parseVector(
        root: json,
        objectKeys: const <String>['position_offset', 'positionOffset'],
        xKeys: const <String>['position_offset_x', 'positionOffsetX'],
        yKeys: const <String>['position_offset_y', 'positionOffsetY'],
        zKeys: const <String>['position_offset_z', 'positionOffsetZ'],
      ),
      rotationOffset: _parseVector(
        root: json,
        objectKeys: const <String>['rotation_offset', 'rotationOffset'],
        xKeys: const <String>['rotation_offset_x', 'rotationOffsetX'],
        yKeys: const <String>['rotation_offset_y', 'rotationOffsetY'],
        zKeys: const <String>['rotation_offset_z', 'rotationOffsetZ'],
      ),
      anchor: _readFirst(json, <String>['anchor'])?.toString(),
      version: _readFirst(json, <String>['version'])?.toString(),
      createdAt: _parseDateTime(_readFirst(json, <String>['created_at', 'createdAt'])),
      updatedAt: _parseDateTime(_readFirst(json, <String>['updated_at', 'updatedAt'])),
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double? get positionOffsetX => positionOffset?.x;
  double? get positionOffsetY => positionOffset?.y;
  double? get positionOffsetZ => positionOffset?.z;

  double? get rotationOffsetX => rotationOffset?.x;
  double? get rotationOffsetY => rotationOffset?.y;
  double? get rotationOffsetZ => rotationOffset?.z;

  GlassesItem copyWith({
    int? id,
    String? name,
    String? brand,
    String? thumbnailUrl,
    double? price,
    double? rating,
    List<String>? tags,
    String? glbUrl,
    double? scale,
    Vec3? positionOffset,
    Vec3? rotationOffset,
    String? anchor,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlassesItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      glbUrl: glbUrl ?? this.glbUrl,
      scale: scale ?? this.scale,
      positionOffset: positionOffset ?? this.positionOffset,
      rotationOffset: rotationOffset ?? this.rotationOffset,
      anchor: anchor ?? this.anchor,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  GlassesItem mergeWith(GlassesItem other) {
    return copyWith(
      id: other.id != 0 ? other.id : id,
      name: other.name != 'Unnamed' ? other.name : name,
      brand: other.brand ?? brand,
      thumbnailUrl: other.thumbnailUrl ?? thumbnailUrl,
      price: other.price != 0 ? other.price : price,
      rating: other.rating ?? rating,
      tags: other.tags.isNotEmpty ? other.tags : tags,
      glbUrl: other.glbUrl ?? glbUrl,
      scale: other.scale ?? scale,
      positionOffset: other.positionOffset ?? positionOffset,
      rotationOffset: other.rotationOffset ?? rotationOffset,
      anchor: other.anchor ?? anchor,
      version: other.version ?? version,
      createdAt: other.createdAt ?? createdAt,
      updatedAt: other.updatedAt ?? updatedAt,
    );
  }

  static dynamic _readFirst(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key];
      }
    }
    return null;
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw is List) {
      return raw
          .map((dynamic value) {
            if (value is String) return value;
            if (value is Map<String, dynamic>) {
              final dynamic name = _readFirst(value, <String>['name', 'label', 'title']);
              return name?.toString() ?? '';
            }
            return value.toString();
          })
          .where((String tag) => tag.trim().isNotEmpty)
          .toList();
    }

    if (raw is String) {
      return raw
          .split(',')
          .map((String value) => value.trim())
          .where((String tag) => tag.isNotEmpty)
          .toList();
    }

    return <String>[];
  }

  static Vec3? _parseVector({
    required Map<String, dynamic> root,
    required List<String> objectKeys,
    required List<String> xKeys,
    required List<String> yKeys,
    required List<String> zKeys,
  }) {
    final dynamic objectValue = _readFirst(root, objectKeys);
    if (objectValue is Map<String, dynamic>) {
      return Vec3.fromJson(objectValue);
    }

    final double? x = parseDouble(_readFirst(root, xKeys));
    final double? y = parseDouble(_readFirst(root, yKeys));
    final double? z = parseDouble(_readFirst(root, zKeys));

    if (x == null && y == null && z == null) {
      return null;
    }

    return Vec3(
      x: x ?? 0,
      y: y ?? 0,
      z: z ?? 0,
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
