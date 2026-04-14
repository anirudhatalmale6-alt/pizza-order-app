import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/menu_item.dart';

class MenuProvider extends ChangeNotifier {
  late Box<MenuItem> _menuBox;
  late Box<ToppingItem> _toppingBox;

  List<MenuItem> get pizzas =>
      _menuBox.values.where((i) => i.type == 'pizza' && i.isActive).toList();

  List<MenuItem> get drinks =>
      _menuBox.values.where((i) => i.type == 'drink' && i.isActive).toList();

  List<MenuItem> get allItems => _menuBox.values.toList();

  List<ToppingItem> get toppings =>
      _toppingBox.values.where((t) => t.isActive).toList();

  List<ToppingItem> get allToppings => _toppingBox.values.toList();

  Future<void> init() async {
    _menuBox = await Hive.openBox<MenuItem>('menu');
    _toppingBox = await Hive.openBox<ToppingItem>('toppings');

    if (_menuBox.isEmpty) {
      await _seedDefaults();
    }
  }

  Future<void> _seedDefaults() async {
    // Default pizzas
    await _menuBox.add(MenuItem(
        name: 'Margherita', nameThai: 'พิซซ่ามาร์การิต้า', price: 150, type: 'pizza'));
    await _menuBox.add(MenuItem(
        name: 'Pepperoni', nameThai: 'พิซซ่าเปปเปอโรนี', price: 160, type: 'pizza'));

    // Default drinks
    await _menuBox.add(
        MenuItem(name: 'Coke', nameThai: 'โค้ก', price: 30, type: 'drink'));
    await _menuBox.add(
        MenuItem(name: 'Fanta', nameThai: 'แฟนต้า', price: 30, type: 'drink'));
    await _menuBox.add(
        MenuItem(name: 'Water', nameThai: 'น้ำเปล่า', price: 20, type: 'drink'));

    // Default toppings
    await _toppingBox.add(
        ToppingItem(name: 'Bacon', nameThai: 'เบคอน', price: 15));
    await _toppingBox.add(
        ToppingItem(name: 'Extra Cheese', nameThai: 'ชีสเพิ่ม', price: 10));
    await _toppingBox.add(
        ToppingItem(name: 'Ham', nameThai: 'แฮม', price: 12));
    await _toppingBox.add(
        ToppingItem(name: 'Pineapple', nameThai: 'สับปะรด', price: 10));
    await _toppingBox.add(
        ToppingItem(name: 'Mushrooms', nameThai: 'เห็ด', price: 10));

    notifyListeners();
  }

  Future<void> addMenuItem(MenuItem item) async {
    await _menuBox.add(item);
    notifyListeners();
  }

  Future<void> updateMenuItem(int index, MenuItem item) async {
    await _menuBox.putAt(index, item);
    notifyListeners();
  }

  Future<void> deleteMenuItem(int index) async {
    await _menuBox.deleteAt(index);
    notifyListeners();
  }

  Future<void> addTopping(ToppingItem item) async {
    await _toppingBox.add(item);
    notifyListeners();
  }

  Future<void> updateTopping(int index, ToppingItem item) async {
    await _toppingBox.putAt(index, item);
    notifyListeners();
  }

  Future<void> deleteTopping(int index) async {
    await _toppingBox.deleteAt(index);
    notifyListeners();
  }
}
