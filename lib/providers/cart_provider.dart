import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  static const _cartKey = 'saved_cart';
  final List<CartItem> _items = [];
  Map<String, double> _categoryDiscounts = {'pizza': 20, 'drink': 5};

  List<CartItem> get items => List.unmodifiable(_items);

  Map<String, double> get categoryDiscounts => Map.unmodifiable(_categoryDiscounts);

  Future<void> restoreCart() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cartKey);
    if (json != null && json.isNotEmpty) {
      try {
        final list = jsonDecode(json) as List;
        _items.clear();
        for (final item in list) {
          _items.add(CartItem.fromJson(item as Map<String, dynamic>));
        }
        notifyListeners();
      } catch (_) {
        await prefs.remove(_cartKey);
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_items.isEmpty) {
      await prefs.remove(_cartKey);
    } else {
      await prefs.setString(_cartKey, jsonEncode(_items.map((i) => i.toJson()).toList()));
    }
  }

  void setCategoryDiscounts(Map<String, double> discounts) {
    _categoryDiscounts = Map.from(discounts);
    notifyListeners();
  }

  double get pizzaDiscount => _categoryDiscounts['pizza'] ?? 0;
  double get drinkDiscount => _categoryDiscounts['drink'] ?? 0;

  int countForCategory(String key) {
    if (key == 'pizza') {
      return _items.where((i) => i.productType == key).length;
    }
    return _items
        .where((i) => i.productType == key)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  double discountForCategory(String key) {
    return countForCategory(key) * (_categoryDiscounts[key] ?? 0);
  }

  int get pizzaCount => countForCategory('pizza');
  int get drinkCount => countForCategory('drink');

  double get subtotal => _items.fold(0, (sum, i) => sum + i.itemTotal);

  double get totalPizzaDiscount => discountForCategory('pizza');
  double get totalDrinkDiscount => discountForCategory('drink');

  double get totalDiscount {
    double total = 0;
    for (final key in _categoryDiscounts.keys) {
      total += discountForCategory(key);
    }
    return total;
  }

  double get finalTotal => (subtotal - totalDiscount).clamp(0, double.infinity);

  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners();
    _persist();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
    _persist();
  }

  void updateQuantity(int index, int qty) {
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = qty;
    }
    notifyListeners();
    _persist();
  }

  void updateItemToppings(int index, List<CartItem> Function(CartItem) updater) {
    final original = _items[index];
    final updated = updater(original);
    if (updated.isNotEmpty) {
      _items[index] = updated.first;
    }
    notifyListeners();
    _persist();
  }

  void replaceItem(int index, CartItem newItem) {
    _items[index] = newItem;
    notifyListeners();
    _persist();
  }

  void duplicateItem(int index) {
    final original = _items[index];
    _items.add(original.copyWith());
    notifyListeners();
    _persist();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  bool get isEmpty => _items.isEmpty;
}
