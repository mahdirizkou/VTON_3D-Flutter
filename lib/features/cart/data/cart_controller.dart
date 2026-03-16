import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../glasses/models/glasses_item.dart';
import '../../orders/models/order_item.dart';
import 'cart_store.dart';

class CartController extends ChangeNotifier {
  CartController._();

  static final CartController instance = CartController._();

  final CartStore _cartStore = CartStore();

  List<OrderItem> _items = <OrderItem>[];
  bool _isLoaded = false;
  String? _activeStorageKey;

  List<OrderItem> get items => List<OrderItem>.unmodifiable(_items);
  bool get isLoaded => _isLoaded;
  int get totalCount => _items.fold<int>(0, (int sum, OrderItem item) => sum + item.quantity);
  double get subtotal => _items.fold<double>(0.0, (double sum, OrderItem item) => sum + item.lineTotal);

  Future<void> ensureLoaded() async {
    final String storageKey = await _cartStore.resolveStorageKey();
    if (_isLoaded && _activeStorageKey == storageKey) {
      return;
    }

    final String? raw = await _cartStore.loadCartJson(storageKey: storageKey);
    _items = _decodeItems(raw);
    _activeStorageKey = storageKey;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> reloadForActiveUser() async {
    _isLoaded = false;
    _activeStorageKey = null;
    _cartStore.clearResolvedKeyCache();
    await ensureLoaded();
  }

  Future<void> addItem(OrderItem item) async {
    await ensureLoaded();
    final int index = _items.indexWhere((OrderItem current) => current.glassesId == item.glassesId);
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
    final int index = _items.indexWhere((OrderItem item) => item.glassesId == glassesId);
    if (index < 0) return;
    final OrderItem current = _items[index];
    _items[index] = current.copyWith(quantity: current.quantity + 1);
    await _persistAndNotify();
  }

  Future<void> decrement(int glassesId) async {
    await ensureLoaded();
    final int index = _items.indexWhere((OrderItem item) => item.glassesId == glassesId);
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
    _items.removeWhere((OrderItem item) => item.glassesId == glassesId);
    await _persistAndNotify();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _items = <OrderItem>[];
    _isLoaded = true;
    await _cartStore.clearCart(storageKey: _activeStorageKey);
    notifyListeners();
  }

  List<OrderItem> _decodeItems(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <OrderItem>[];
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <OrderItem>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                OrderItem.fromCartJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return <OrderItem>[];
    }
  }

  Future<void> _persistAndNotify() async {
    final String storageKey = _activeStorageKey ?? await _cartStore.resolveStorageKey();
    final String encoded = jsonEncode(
      _items.map((OrderItem item) => item.toCartJson()).toList(),
    );
    _activeStorageKey = storageKey;
    await _cartStore.saveCartJson(
      encoded,
      storageKey: storageKey,
    );
    notifyListeners();
  }
}
