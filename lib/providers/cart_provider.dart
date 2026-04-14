import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _pizzaDiscount = 20;
  double _drinkDiscount = 5;

  List<CartItem> get items => List.unmodifiable(_items);

  double get pizzaDiscount => _pizzaDiscount;
  double get drinkDiscount => _drinkDiscount;

  set pizzaDiscount(double v) { _pizzaDiscount = v; notifyListeners(); }
  set drinkDiscount(double v) { _drinkDiscount = v; notifyListeners(); }

  int get pizzaCount => _items.where((i) => i.productType == 'pizza').length;
  int get drinkCount => _items
      .where((i) => i.productType == 'drink')
      .fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.itemTotal);
  double get totalPizzaDiscount => pizzaCount * _pizzaDiscount;
  double get totalDrinkDiscount => drinkCount * _drinkDiscount;
  double get totalDiscount => totalPizzaDiscount + totalDrinkDiscount;
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
