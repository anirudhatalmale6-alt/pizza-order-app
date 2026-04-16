import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';
import '../models/category_config.dart';
import '../services/google_sheet_service.dart';

class MenuProvider extends ChangeNotifier {
  static const _appDataVersion = 3; // Bump this to force clear old data

  late Box<MenuItem> _menuBox;
  late Box<ToppingItem> _toppingBox;
  List<CategoryConfig> _categories = [];
  String _sheetId = '';
  String _lastSyncResult = '';
  bool _syncedFromSheet = false;

  List<CategoryConfig> get categories => List.unmodifiable(_categories);
  String get sheetId => _sheetId;
  String get lastSyncError => _lastSyncResult;
  bool get syncedFromSheet => _syncedFromSheet;

  List<MenuItem> itemsForCategory(String key) =>
      _menuBox.values.where((i) => i.type == key && i.isActive).toList();

  List<MenuItem> get pizzas => itemsForCategory('pizza');
  List<MenuItem> get drinks => itemsForCategory('drink');

  List<MenuItem> get allItems => _menuBox.values.toList();

  List<ToppingItem> get toppings =>
      _toppingBox.values.where((t) => t.isActive).toList();

  List<ToppingItem> get allToppings => _toppingBox.values.toList();

  Future<void> init() async {
    _menuBox = await Hive.openBox<MenuItem>('menu');
    _toppingBox = await Hive.openBox<ToppingItem>('toppings');

    final prefs = await SharedPreferences.getInstance();

    // Clear old cached data when app version changes
    final storedVersion = prefs.getInt('appDataVersion') ?? 0;
    if (storedVersion < _appDataVersion) {
      await _menuBox.clear();
      await _toppingBox.clear();
      await prefs.remove('cachedCategories');
      await prefs.remove('googleSheetId');
      await prefs.setInt('appDataVersion', _appDataVersion);
    }

    // Load sheet ID
    final storedId = prefs.getString('googleSheetId') ?? '';
    _sheetId = storedId.isNotEmpty
        ? GoogleSheetService.extractSheetId(storedId)
        : '14NlT5XPpuBIEe-v9aoGvSvXbGdldq9pCWvgUdQeayug';
    if (storedId != _sheetId) {
      await prefs.setString('googleSheetId', _sheetId);
    }

    // Load cached categories
    final cachedCats = prefs.getString('cachedCategories');
    if (cachedCats != null) {
      final list = jsonDecode(cachedCats) as List;
      _categories = list.map((e) => CategoryConfig.fromJson(e)).toList();
    }

    // Try to sync
    if (_sheetId.isNotEmpty) {
      await syncFromSheet();
    }

    // Fallback to defaults only if nothing loaded
    if (_categories.isEmpty) {
      _categories = _defaultCategories();
    }
    if (_menuBox.isEmpty) {
      await _seedDefaults();
    }

    notifyListeners();
  }

  Future<bool> syncFromSheet() async {
    if (_sheetId.isEmpty) {
      _lastSyncResult = 'No Sheet ID configured';
      return false;
    }
    try {
      final data = await GoogleSheetService.fetchAll(_sheetId);

      // Update categories
      _categories = data.categories;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedCategories',
          jsonEncode(_categories.map((c) => c.toJson()).toList()));

      // Update menu items
      await _menuBox.clear();
      for (final item in data.menuItems) {
        await _menuBox.add(item);
      }

      // Update toppings
      await _toppingBox.clear();
      for (final item in data.toppings) {
        await _toppingBox.add(item);
      }

      _syncedFromSheet = true;
      _lastSyncResult = 'Source: ${data.source.toUpperCase()}\n'
          '${data.menuItems.length} menu items\n'
          '${data.categories.length} categories\n'
          '${data.toppings.length} toppings';
      notifyListeners();
      return true;
    } catch (e) {
      _lastSyncResult = GoogleSheetService.lastError.isNotEmpty
          ? GoogleSheetService.lastError
          : e.toString();
      debugPrint('Sheet sync failed: $_lastSyncResult');
      _syncedFromSheet = false;
      return false;
    }
  }

  Future<void> saveSheetId(String id) async {
    _sheetId = GoogleSheetService.extractSheetId(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('googleSheetId', _sheetId);
    notifyListeners();
  }

  Map<String, double> get categoryDiscounts => {
        for (final cat in _categories) cat.key: cat.discount,
      };

  CategoryConfig? categoryFor(String key) {
    try {
      return _categories.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  static List<CategoryConfig> _defaultCategories() => [
        CategoryConfig(key: 'pizza', label: 'Pizza', labelThai: 'พิซซ่า',
            icon: 'local_pizza', color: 'deepOrange', discount: 20, sortOrder: 1, hasToppings: true),
        CategoryConfig(key: 'drink', label: 'Drinks', labelThai: 'เครื่องดื่ม',
            icon: 'local_drink', color: 'blue', discount: 5, sortOrder: 2, hasToppings: false),
      ];

  Future<void> _seedDefaults() async {
    await _menuBox.add(MenuItem(name: 'Margherita', nameThai: 'พิซซ่ามาร์การิต้า', price: 159, type: 'pizza'));
    await _menuBox.add(MenuItem(name: 'Spicy Peanut', nameThai: 'พิซซ่าถั่วเผ็ด', price: 159, type: 'pizza'));
    await _menuBox.add(MenuItem(name: 'Espresso (Hot)', nameThai: 'เอสเปรสโซ่ (ร้อน)', price: 40, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Americano (Hot)', nameThai: 'อเมริกาโน่ (ร้อน)', price: 40, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Cappuccino (Hot)', nameThai: 'คาปูชิโน่ (ร้อน)', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Latte (Hot)', nameThai: 'ลาเต้ (ร้อน)', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Espresso (Iced)', nameThai: 'เอสเปรสโซ่ (เย็น)', price: 45, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Americano (Iced)', nameThai: 'อเมริกาโน่ (เย็น)', price: 45, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Cappuccino (Iced)', nameThai: 'คาปูชิโน่ (เย็น)', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Latte (Iced)', nameThai: 'ลาเต้ (เย็น)', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Mango Soda', nameThai: 'น้ำมะม่วงโซดา', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Apple Soda', nameThai: 'โซดาแอปเปิ้ล', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Orange Soda', nameThai: 'น้ำส้มโซดา', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Passion Fruit Soda', nameThai: 'โซดารสเสาวรส', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Pineapple Soda', nameThai: 'น้ำสับปะรดโซดา', price: 55, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Lychee Fruit Tea', nameThai: 'ชาลิ้นจี่', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Peach Fruit Tea', nameThai: 'ชาพีช', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Thai Milk Tea', nameThai: 'ชานมไทย', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Taiwanese Bubble Tea', nameThai: 'ชานมมุขไต้หวั่น', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Apple Tea', nameThai: 'ชาแอปเปิล', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Punch', nameThai: 'พั้นซ์', price: 50, type: 'drink'));
    await _menuBox.add(MenuItem(name: 'Matcha', nameThai: 'มัทฉะ', price: 70, type: 'drink'));
    await _toppingBox.add(ToppingItem(name: 'Extra Cheese', nameThai: 'ชีสเพิ่ม', price: 45));
    await _toppingBox.add(ToppingItem(name: 'Ham', nameThai: 'แฮม', price: 50));
    await _toppingBox.add(ToppingItem(name: 'Bacon', nameThai: 'เบคอน', price: 60));
    await _toppingBox.add(ToppingItem(name: 'Shrimp', nameThai: 'กุ้ง', price: 50));
    await _toppingBox.add(ToppingItem(name: 'Tomato', nameThai: 'มะเขือเทศ', price: 25));
    await _toppingBox.add(ToppingItem(name: 'Onion', nameThai: 'หัวหอม', price: 25));
    await _toppingBox.add(ToppingItem(name: 'Bell Pepper', nameThai: 'พริกหวาน', price: 30));
    await _toppingBox.add(ToppingItem(name: 'Pineapple', nameThai: 'สัปปะรด', price: 30));
    await _toppingBox.add(ToppingItem(name: 'Mushroom', nameThai: 'เห็ด', price: 45));
    notifyListeners();
  }

  Future<void> addMenuItem(MenuItem item) async { await _menuBox.add(item); notifyListeners(); }
  Future<void> updateMenuItem(int index, MenuItem item) async { await _menuBox.putAt(index, item); notifyListeners(); }
  Future<void> deleteMenuItem(int index) async { await _menuBox.deleteAt(index); notifyListeners(); }
  Future<void> addTopping(ToppingItem item) async { await _toppingBox.add(item); notifyListeners(); }
  Future<void> updateTopping(int index, ToppingItem item) async { await _toppingBox.putAt(index, item); notifyListeners(); }
  Future<void> deleteTopping(int index) async { await _toppingBox.deleteAt(index); notifyListeners(); }
}
