import 'dart:convert';
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
  static const _timeout = Duration(seconds: 20);

  // GitHub raw URL for fallback
  static const _githubJsonUrl =
      'https://raw.githubusercontent.com/anirudhatalmale6-alt/pizza-order-app/master/assets/menu_data.json';

  /// Extract sheet ID from a full URL or return as-is if already an ID
  static String extractSheetId(String input) {
    input = input.trim();
    final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(input);
    if (match != null) return match.group(1)!;
    return input;
  }

  static String _gvizUrl(String sheetId, String tabName) =>
      'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&sheet=${Uri.encodeComponent(tabName)}';

  static Future<List<List<dynamic>>> _fetchCsvTab(
      String sheetId, String tabName) async {
    final url = _gvizUrl(sheetId, tabName);
    final response = await http.get(Uri.parse(url), headers: {
      'Accept': 'text/csv',
      'User-Agent': 'JensPizzeria/3.0',
    }).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final body = response.body.trim();
    if (body.startsWith('<!') || body.startsWith('<html') || body.startsWith('<HTML')) {
      throw Exception('Got HTML instead of CSV');
    }
    if (body.isEmpty) {
      throw Exception('Empty response');
    }
    final rows = const CsvToListConverter().convert(body);
    if (rows.isEmpty) throw Exception('No rows parsed');
    return rows;
  }

  /// Last sync error message (for showing in UI)
  static String lastError = '';

  static Future<SheetData> fetchAll(String sheetId) async {
    lastError = '';

    // Try Google Sheets CSV first
    try {
      final menuRows = await _fetchCsvTab(sheetId, 'menu');
      final toppingRows = await _fetchCsvTab(sheetId, 'toppings');
      final categoryRows = await _fetchCsvTab(sheetId, 'categories');

      final categories = _parseCategories(categoryRows);
      final menuItems = _parseMenu(menuRows);
      final toppings = _parseToppings(toppingRows);

      return SheetData(
        categories: categories,
        menuItems: menuItems,
        toppings: toppings,
      );
    } catch (e) {
      lastError = 'Google Sheet: $e';
    }

    // Fall back to GitHub JSON
    try {
      return await _fetchFromGitHub();
    } catch (e2) {
      lastError = '$lastError | GitHub: $e2';
      throw Exception(lastError);
    }
  }

  static Future<SheetData> _fetchFromGitHub() async {
    final response = await http.get(Uri.parse(_githubJsonUrl), headers: {
      'User-Agent': 'JensPizzeria/3.0',
    }).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final categoriesList = (data['categories'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final menuList = (data['menu'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final toppingsList = (data['toppings'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return SheetData(
      categories: _parseCategoriesFromJson(categoriesList),
      menuItems: _parseMenuFromJson(menuList),
      toppings: _parseToppingsFromJson(toppingsList),
    );
  }

  // ======= CSV parsers =======

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
      result.add(_buildCategory(map));
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
      result.add(_buildMenuItem(map));
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
      result.add(_buildToppingItem(map));
    }

    return result;
  }

  // ======= JSON parsers =======

  static List<CategoryConfig> _parseCategoriesFromJson(List<Map<String, dynamic>> items) {
    final result = items.map((map) {
      // Lowercase all keys for consistency
      final m = map.map((k, v) => MapEntry(k.toLowerCase(), v));
      return _buildCategory(m);
    }).toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  static List<MenuItem> _parseMenuFromJson(List<Map<String, dynamic>> items) {
    return items.map((map) {
      final m = map.map((k, v) => MapEntry(k.toLowerCase(), v));
      return _buildMenuItem(m);
    }).toList();
  }

  static List<ToppingItem> _parseToppingsFromJson(List<Map<String, dynamic>> items) {
    return items.map((map) {
      final m = map.map((k, v) => MapEntry(k.toLowerCase(), v));
      return _buildToppingItem(m);
    }).toList();
  }

  // ======= Shared builders =======

  static CategoryConfig _buildCategory(Map<String, dynamic> map) {
    return CategoryConfig(
      key: _str(map['key']),
      label: _str(map['label']),
      labelThai: _str(map['labelthai']),
      icon: _strOrFallback(map['icon'], 'restaurant'),
      color: _strOrFallback(map['color'], 'deepOrange'),
      discount: _num(map['discount']),
      sortOrder: _num(map['sortorder']).toInt(),
      hasToppings: _bool(map['hastoppings']),
    );
  }

  static MenuItem _buildMenuItem(Map<String, dynamic> map) {
    return MenuItem(
      name: _str(map['name']),
      nameThai: _str(map['namethai']),
      price: _num(map['price']),
      type: _str(map['category'], 'drink'),
      isActive: _bool(map['isactive'], true),
    );
  }

  static ToppingItem _buildToppingItem(Map<String, dynamic> map) {
    return ToppingItem(
      name: _str(map['name']),
      nameThai: _str(map['namethai']),
      price: _num(map['price']),
      isActive: _bool(map['isactive'], true),
    );
  }

  // ======= Helpers =======

  static String _str(dynamic val, [String fallback = '']) =>
      val?.toString().trim() ?? fallback;

  static String _strOrFallback(dynamic val, String fallback) {
    final s = val?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

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
