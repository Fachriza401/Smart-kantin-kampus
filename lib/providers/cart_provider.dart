import 'package:flutter/foundation.dart';

import '../db/db_helper.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  double _discountPercent = 0;
  String? _promoTitle;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalQty {
    return _items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  double get subtotal {
    return _items.fold(
      0,
      (sum, item) => sum + item.subtotal,
    );
  }

  double get discount {
    return subtotal * (_discountPercent / 100);
  }

  double get total {
    return (subtotal - discount).clamp(0, double.infinity).toDouble();
  }

  double get discountPercent => _discountPercent;

  String? get promoTitle => _promoTitle;

  String? get tenantName {
    if (_items.isEmpty) return null;
    return _items.first.menuItem.tenantName;
  }

  Future<void> loadActivePromo() async {
    final promo = await DBHelper.instance.getBestActivePromo();

    _discountPercent = promo?.discount ?? 0;
    _promoTitle = promo?.title;

    notifyListeners();
  }

  void addItem(
    MenuItem menuItem, {
    int quantity = 1,
  }) {
    if (quantity <= 0) return;

    if (!menuItem.tersedia) {
      debugPrint(
        'ADD CART DITOLAK | menu=${menuItem.name} | alasan=stok habis',
      );
      return;
    }

    final index = _items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          menuItem: menuItem,
          quantity: quantity,
        ),
      );
    }

    debugPrint(
      'ADD CART | provider=${identityHashCode(this)} '
      '| menu=${menuItem.name} '
      '| id=${menuItem.id} '
      '| qty=$quantity '
      '| totalQty=$totalQty '
      '| items=${_items.length} '
      '| subtotal=$subtotal '
      '| total=$total',
    );

    notifyListeners();
  }

  void setQuantity(int menuId, int quantity) {
    final index = _items.indexWhere(
      (item) => item.menuItem.id == menuId,
    );

    if (index == -1) return;

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }

    notifyListeners();
  }

  void increment(int menuId) {
    final index = _items.indexWhere(
      (item) => item.menuItem.id == menuId,
    );

    if (index == -1) return;

    _items[index].quantity++;

    notifyListeners();
  }

  void decrement(int menuId) {
    final index = _items.indexWhere(
      (item) => item.menuItem.id == menuId,
    );

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }

    notifyListeners();
  }

  void removeItem(int menuId) {
    _items.removeWhere(
      (item) => item.menuItem.id == menuId,
    );

    notifyListeners();
  }

  void clear() {
    _items.clear();
    _discountPercent = 0;
    _promoTitle = null;

    notifyListeners();
  }
}
