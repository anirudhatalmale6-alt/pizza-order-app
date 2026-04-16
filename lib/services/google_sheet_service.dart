import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import '../models/category_config.dart';
import '../models/menu_item.dart';

class SheetData {
  final List<CategoryConfig> categories;
  final List<MenuItem> menuItems;
  final List<ToppingItem> toppings;

  SheetData({
    required this.categories,
    required this.menuItems,
    required this.toppings,
  });
}

class GoogleSheetService {
  static const _timeout = Duration(seconds: 8);

  static String _csvUrl(String sheetId, String tabName) =>
      'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&sheet=${Uri.encodeComponent(tabName)}';

  static Future<List<List<dynamic>>> _fetchTab(
      String sheetId, String tabName) async {
    final url = _csvUrl(sheetId, tabName);
    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch $tabName: ${response.statusCode}');
    }
    final rows = const CsvToListConverter().convert(response.body);
    if (rows.isEmpty) return [];
    // First row is header, rest is data
    return rows;
  }

  static Future<SheetData> fetchAll(String sheetId) async {
    final menuRows = await _fetchTab(sheetId, 'menu');
    final toppingRows = await _fetchTab(sheetId, 'toppings');
    final categoryRows = await _fetchTab(sheetId, 'categories');

    final categories = _parseCategories(categoryRows);
    final menuItems = _parseMenu(menuRows);
    final toppings = _parseToppings(toppingRows);

    return SheetData(
      categories: categories,
      menuItems: menuItems,
      toppings: toppings,
    );
  }

  static List<CategoryConfig> _parseCategories(List<List<dynamic>> rows) {
    if (rows.length < 2) return [];
    final header = rows[0].map((e) => e.toString().trim().toLowerCase()).toList();
    final result = <CategoryConfig>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final map = <String, dynamic>{};
      for (int j = 0; j < header.length && j < row.length; j++) {
        map[header[j]] = row[j];
      }
      result.add(CategoryConfig(
        key: _str(map['key']),
        label: _str(map['label']),
        labelThai: _str(map['labelthai']),
        icon: _str(map['icon'], 'restaurant'),
        color: _str(map['color'], 'deepOrange'),
        discount: _num(map['discount']),
        sortOrder: _num(map['sortorder']).toInt(),
        hasToppings: _bool(map['hastoppings']),
      ));
    }

    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  static List<MenuItem> _parseMenu(List<List<dynamic>> rows) {
    if (rows.length < 2) return [];
    final header = rows[0].map((e) => e.toString().trim().toLowerCase()).toList();
    final result = <MenuItem>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final map = <String, dynamic>{};
      for (int j = 0; j < header.length && j < row.length; j++) {
        map[header[j]] = row[j];
      }
      result.add(MenuItem(
        name: _str(map['name']),
        nameThai: _str(map['namethai']),
        price: _num(map['price']),
        type: _str(map['category'], 'drink'),
        isActive: _bool(map['isactive'], true),
      ));
    }

    return result;
  }

  static List<ToppingItem> _parseToppings(List<List<dynamic>> rows) {
    if (rows.length < 2) return [];
    final header = rows[0].map((e) => e.toString().trim().toLowerCase()).toList();
    final result = <ToppingItem>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final map = <String, dynamic>{};
      for (int j = 0; j < header.length && j < row.length; j++) {
        map[header[j]] = row[j];
      }
      result.add(ToppingItem(
        name: _str(map['name']),
        nameThai: _str(map['namethai']),
        price: _num(map['price']),
        isActive: _bool(map['isactive'], true),
      ));
    }

    return result;
  }

  static String _str(dynamic val, [String fallback = '']) =>
      val?.toString().trim() ?? fallback;

  static double _num(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic val, [bool fallback = false]) {
    if (val is bool) return val;
    final s = val?.toString().trim().toLowerCase() ?? '';
    if (s == 'true' || s == 'yes' || s == '1') return true;
    if (s == 'false' || s == 'no' || s == '0') return false;
    return fallback;
  }
}
