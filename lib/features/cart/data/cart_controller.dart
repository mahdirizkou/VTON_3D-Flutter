import 'package:flutter/foundation.dart';

import '../../glasses/models/glasses_item.dart';
import '../models/cart_item.dart';
import 'cart_store.dart';

class CartController extends ChangeNotifier {
  CartController._();

  static final CartController instance = CartController._();

  final CartStore _store = CartStore();
  List<CartItem> _items = <CartItem>[];
  bool _isLoaded = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;

  int get totalCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    _items = await _store.loadCart();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addFromGlasses(GlassesItem item, {int quantity = 1}) async {
    await ensureLoaded();
    final index = _items.indexWhere((e) => e.itemId == item.id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + quantity);
    } else {
      _items.add(
        CartItem(
          itemId: item.id,
          name: item.name,
          price: item.price,
          quantity: quantity,
          thumbnailUrl: item.thumbnailUrl,
        ),
      );
    }
    await _persistAndNotify();
  }

  Future<void> increment(int itemId) async {
    await ensureLoaded();
    final index = _items.indexWhere((e) => e.itemId == itemId);
    if (index < 0) return;
    final current = _items[index];
    _items[index] = current.copyWith(quantity: current.quantity + 1);
    await _persistAndNotify();
  }

  Future<void> decrement(int itemId) async {
    await ensureLoaded();
    final index = _items.indexWhere((e) => e.itemId == itemId);
    if (index < 0) return;
    final current = _items[index];
    if (current.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = current.copyWith(quantity: current.quantity - 1);
    }
    await _persistAndNotify();
  }

  Future<void> removeItem(int itemId) async {
    await ensureLoaded();
    _items.removeWhere((e) => e.itemId == itemId);
    await _persistAndNotify();
  }

  Future<void> clearCart() async {
    _items = <CartItem>[];
    _isLoaded = true;
    await _store.clearCart();
    notifyListeners();
  }

  Future<void> _persistAndNotify() async {
    await _store.saveCart(_items);
    notifyListeners();
  }
}
