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
    // Pizzas
    await _menuBox.add(MenuItem(
        name: 'Margherita', nameThai: 'พิซซ่ามาร์การิต้า', price: 159, type: 'pizza'));
    await _menuBox.add(MenuItem(
        name: 'Spicy Peanut', nameThai: 'พิซซ่าถั่วเผ็ด', price: 159, type: 'pizza'));

    // Hot Coffee
    await _menuBox.add(MenuItem(
        name: 'Espresso (Hot)', nameThai: 'เอสเปรสโซ่ (ร้อน)', price: 40, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Americano (Hot)', nameThai: 'อเมริกาโน่ (ร้อน)', price: 40, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Cappuccino (Hot)', nameThai: 'คาปูชิโน่ (ร้อน)', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Latte (Hot)', nameThai: 'ลาเต้ (ร้อน)', price: 50, type: 'drink'));

    // Iced Coffee
    await _menuBox.add(MenuItem(
        name: 'Espresso (Iced)', nameThai: 'เอสเปรสโซ่ (เย็น)', price: 45, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Americano (Iced)', nameThai: 'อเมริกาโน่ (เย็น)', price: 45, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Cappuccino (Iced)', nameThai: 'คาปูชิโน่ (เย็น)', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Latte (Iced)', nameThai: 'ลาเต้ (เย็น)', price: 55, type: 'drink'));

    // Sodas
    await _menuBox.add(MenuItem(
        name: 'Mango Soda', nameThai: 'น้ำมะม่วงโซดา', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Apple Soda', nameThai: 'โซดาแอปเปิ้ล', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Orange Soda', nameThai: 'น้ำส้มโซดา', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Passion Fruit Soda', nameThai: 'โซดารสเสาวรส', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Pineapple Soda', nameThai: 'น้ำสับปะรดโซดา', price: 55, type: 'drink'));

    // Teas & Others
    await _menuBox.add(MenuItem(
        name: 'Lychee Fruit Tea', nameThai: 'ชาลิ้นจี่', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Peach Fruit Tea', nameThai: 'ชาพีช', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Thai Milk Tea', nameThai: 'ชานมไทย', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Taiwanese Bubble Tea', nameThai: 'ชานมมุขไต้หวั่น', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Apple Tea', nameThai: 'ชาแอปเปิล', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Punch', nameThai: 'พั้นซ์', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(
        name: 'Matcha', nameThai: 'มัทฉะ', price: 70, type: 'drink'));

    // Pizza Toppings
    await _toppingBox.add(
        ToppingItem(name: 'Extra Cheese', nameThai: 'ชีสเพิ่ม', price: 45));
    await _toppingBox.add(
        ToppingItem(name: 'Ham', nameThai: 'แฮม', price: 50));
    await _toppingBox.add(
        ToppingItem(name: 'Bacon', nameThai: 'เบคอน', price: 60));
    await _toppingBox.add(
        ToppingItem(name: 'Shrimp', nameThai: 'กุ้ง', price: 50));
    await _toppingBox.add(
        ToppingItem(name: 'Tomato', nameThai: 'มะเขือเทศ', price: 25));
    await _toppingBox.add(
        ToppingItem(name: 'Onion', nameThai: 'หัวหอม', price: 25));
    await _toppingBox.add(
        ToppingItem(name: 'Bell Pepper', nameThai: 'พริกหวาน', price: 30));
    await _toppingBox.add(
        ToppingItem(name: 'Pineapple', nameThai: 'สัปปะรด', price: 30));
    await _toppingBox.add(
        ToppingItem(name: 'Mushroom', nameThai: 'เห็ด', price: 45));

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
