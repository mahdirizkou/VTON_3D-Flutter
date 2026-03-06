import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../glasses/models/glasses_item.dart';
import '../../orders/models/order_item.dart';

class CartController extends ChangeNotifier {
  CartController._();

  static final CartController instance = CartController._();

  static const String _storageKey = 'cart_items';

  List<OrderItem> _items = <OrderItem>[];
  bool _isLoaded = false;

  List<OrderItem> get items => List<OrderItem>.unmodifiable(_items);
  bool get isLoaded => _isLoaded;
  int get totalCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold<double>(0.0, (sum, item) => sum + item.lineTotal);

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _items = <OrderItem>[];
    } else {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          _items = decoded
              .whereType<Map>()
              .map((e) => OrderItem.fromCartJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          _items = <OrderItem>[];
        }
      } catch (_) {
        _items = <OrderItem>[];
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addItem(OrderItem item) async {
    await ensureLoaded();
    final int index = _items.indexWhere((e) => e.glassesId == item.glassesId);
    if (index >= 0) {
      final OrderItem current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + item.quantity);
    } else {
      _items.add(item);
    }
    await _persistAndNotify();
  }

  Future<void> addFromGlasses(GlassesItem item, {int quantity = 1}) async {
    await addItem(OrderItem.fromGlasses(item, quantity: quantity));
  }

  Future<void> increment(int glassesId) async {
    await ensureLoaded();
    final int index = _items.indexWhere((e) => e.glassesId == glassesId);
    if (index < 0) return;
    final OrderItem current = _items[index];
    _items[index] = current.copyWith(quantity: current.quantity + 1);
    await _persistAndNotify();
  }

  Future<void> decrement(int glassesId) async {
    await ensureLoaded();
    final int index = _items.indexWhere((e) => e.glassesId == glassesId);
    if (index < 0) return;
    final OrderItem current = _items[index];
    if (current.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = current.copyWith(quantity: current.quantity - 1);
    }
    await _persistAndNotify();
  }

  Future<void> remove(int glassesId) async {
    await ensureLoaded();
    _items.removeWhere((e) => e.glassesId == glassesId);
    await _persistAndNotify();
  }

  Future<void> clear() async {
    _items = <OrderItem>[];
    _isLoaded = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Future<void> _persistAndNotify() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_items.map((e) => e.toCartJson()).toList());
    await prefs.setString(_storageKey, encoded);
    notifyListeners();
  }
}
