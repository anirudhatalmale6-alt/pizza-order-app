import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  Map<String, double> _categoryDiscounts = {'pizza': 20, 'drink': 5};

  List<CartItem> get items => List.unmodifiable(_items);

  Map<String, double> get categoryDiscounts => Map.unmodifiable(_categoryDiscounts);

  void setCategoryDiscounts(Map<String, double> discounts) {
    _categoryDiscounts = Map.from(discounts);
    notifyListeners();
  }

  // Legacy getters for backward compatibility
  double get pizzaDiscount => _categoryDiscounts['pizza'] ?? 0;
  double get drinkDiscount => _categoryDiscounts['drink'] ?? 0;

  int countForCategory(String key) {
    if (key == 'pizza') {
      // Pizzas count by items (each pizza is 1, even with quantity)
      return _items.where((i) => i.productType == key).length;
    }
    // Everything else counts by quantity
    return _items
        .where((i) => i.productType == key)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  double discountForCategory(String key) {
    return countForCategory(key) * (_categoryDiscounts[key] ?? 0);
  }

  // Legacy getters
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
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int qty) {
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = qty;
    }
    notifyListeners();
  }

  void duplicateItem(int index) {
    final original = _items[index];
    _items.add(original.copyWith());
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool get isEmpty => _items.isEmpty;
}
