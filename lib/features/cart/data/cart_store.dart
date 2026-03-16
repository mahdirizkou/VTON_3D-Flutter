import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/token_store.dart';
import '../../auth/data/auth_api.dart';
import '../models/cart_item.dart';

class CartStore {
  CartStore({AuthApi? authApi}) : _authApi = authApi ?? AuthApi();

  static const String _cartKeyPrefix = 'cart_items_v1';
  static const String _guestCartKey = '${_cartKeyPrefix}_guest';

  final AuthApi _authApi;

  String? _cachedAccessToken;
  String? _cachedStorageKey;

  Future<List<CartItem>> loadCart({String? storageKey}) async {
    final String? raw = await loadCartJson(storageKey: storageKey);
    if (raw == null || raw.isEmpty) return const <CartItem>[];

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const <CartItem>[];

      return decoded
          .whereType<Map>()
          .map((Map<dynamic, dynamic> item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const <CartItem>[];
    }
  }

  Future<void> saveCart(List<CartItem> items, {String? storageKey}) async {
    final String encoded = jsonEncode(items.map((CartItem item) => item.toJson()).toList());
    await saveCartJson(encoded, storageKey: storageKey);
  }

  Future<void> clearCart({String? storageKey}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = storageKey ?? await resolveStorageKey();
    await prefs.remove(key);
  }

  Future<String?> loadCartJson({String? storageKey}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = storageKey ?? await resolveStorageKey();
    return prefs.getString(key);
  }

  Future<void> saveCartJson(String encodedCart, {String? storageKey}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = storageKey ?? await resolveStorageKey();
    await prefs.setString(key, encodedCart);
  }

  Future<String> resolveStorageKey() async {
    final String? accessToken = await TokenStore.instance.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      _cacheResolvedKey(
        accessToken: null,
        storageKey: _guestCartKey,
      );
      return _guestCartKey;
    }

    if (_cachedAccessToken == accessToken && _cachedStorageKey != null) {
      return _cachedStorageKey!;
    }

    try {
      final Map<String, dynamic> me = await _authApi.me();
      final String key = _buildAuthenticatedCartKey(
        profile: me,
        accessToken: accessToken,
      );
      _cacheResolvedKey(
        accessToken: accessToken,
        storageKey: key,
      );
      return key;
    } on ApiUnauthorizedException {
      _cacheResolvedKey(
        accessToken: null,
        storageKey: _guestCartKey,
      );
      return _guestCartKey;
    } catch (_) {
      final String fallbackKey = '${_cartKeyPrefix}_auth_${_hashToken(accessToken)}';
      _cacheResolvedKey(
        accessToken: accessToken,
        storageKey: fallbackKey,
      );
      return fallbackKey;
    }
  }

  void clearResolvedKeyCache() {
    _cachedAccessToken = null;
    _cachedStorageKey = null;
  }

  String _buildAuthenticatedCartKey({
    required Map<String, dynamic> profile,
    required String accessToken,
  }) {
    final dynamic userId = profile['id'];
    if (userId != null && userId.toString().trim().isNotEmpty) {
      return '${_cartKeyPrefix}_user_${_sanitizeSegment(userId.toString())}';
    }

    final String? email = profile['email']?.toString();
    if (email != null && email.trim().isNotEmpty) {
      return '${_cartKeyPrefix}_email_${_sanitizeSegment(email.toLowerCase())}';
    }

    final String? username = profile['username']?.toString();
    if (username != null && username.trim().isNotEmpty) {
      return '${_cartKeyPrefix}_user_${_sanitizeSegment(username.toLowerCase())}';
    }

    return '${_cartKeyPrefix}_auth_${_hashToken(accessToken)}';
  }

  void _cacheResolvedKey({
    required String? accessToken,
    required String storageKey,
  }) {
    _cachedAccessToken = accessToken;
    _cachedStorageKey = storageKey;
  }

  String _sanitizeSegment(String value) {
    final String sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return sanitized.isEmpty ? 'unknown' : sanitized;
  }

  String _hashToken(String token) {
    int hash = 0;
    for (final int unit in token.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}
