import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/category_config.dart';
import '../models/menu_item.dart';

class SheetData {
  final List<CategoryConfig> categories;
  final List<MenuItem> menuItems;
  final List<ToppingItem> toppings;
  final String source; // 'google', 'github', or 'bundled'

  SheetData({
    required this.categories,
    required this.menuItems,
    required this.toppings,
    this.source = 'unknown',
  });
}

class GoogleSheetService {
  static const _timeout = Duration(seconds: 20);

  static const _githubJsonUrl =
      'https://github.com/anirudhatalmale6-alt/pizza-order-app/raw/master/assets/menu_data.json';

  /// Extract sheet ID from a full URL or return as-is if already an ID
  static String extractSheetId(String input) {
    input = input.trim();
    // Handle full Google Sheets URL
    final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(input);
    if (match != null) return match.group(1)!;
    // If it looks like a URL but we couldn't parse it, reject
    if (input.startsWith('http')) return '';
    return input;
  }

  static String _gvizBaseUrl(String sheetId, String tabName) =>
      'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&sheet=${Uri.encodeComponent(tabName)}';

  static List<String> _corsProxiedUrls(String baseUrl) => [
    'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(baseUrl)}',
    'https://corsproxy.io/?${Uri.encodeComponent(baseUrl)}',
  ];

  static String _lastRawPreview = '';

  static Future<List<List<dynamic>>> _fetchCsvTab(
      String sheetId, String tabName) async {
    final baseUrl = _gvizBaseUrl(sheetId, tabName);

    if (!kIsWeb) {
      return _fetchCsvFromUrl(baseUrl, tabName);
    }

    final urls = _corsProxiedUrls(baseUrl);
    Exception? lastErr;
    for (final url in urls) {
      try {
        return await _fetchCsvFromUrl(url, tabName);
      } catch (e) {
        lastErr = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastErr ?? Exception('All CORS proxies failed for $tabName');
  }

  static Future<List<List<dynamic>>> _fetchCsvFromUrl(
      String url, String tabName) async {
    final response = await http.get(Uri.parse(url), headers: {
      'Accept': 'text/csv',
    }).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} for $tabName');
    }
    final body = response.body.trim();
    final preview = body.length > 150 ? body.substring(0, 150) : body;
    _lastRawPreview = '[$tabName] ${body.length} chars: $preview';

    if (body.startsWith('<!') || body.startsWith('<html') || body.startsWith('<HTML')) {
      throw Exception('Got HTML instead of CSV ($tabName): ${body.substring(0, 80)}');
    }
    if (body.isEmpty) {
      throw Exception('Empty response for $tabName');
    }
    final rows = const CsvToListConverter(eol: '\n').convert(body);
    if (rows.isEmpty) throw Exception('No rows parsed for $tabName');
    return rows;
  }

  /// Last sync error and source
  static String lastError = '';
  static String lastSource = '';
  static String debugInfo = '';

  static Future<SheetData> fetchAll(String sheetId) async {
    lastError = '';
    lastSource = '';
    debugInfo = '';

    // Try 1: Google Sheets CSV
    if (sheetId.isNotEmpty && !sheetId.startsWith('http')) {
      try {
        final menuRows = await _fetchCsvTab(sheetId, 'menu');
        final toppingRows = await _fetchCsvTab(sheetId, 'toppings');
        final categoryRows = await _fetchCsvTab(sheetId, 'categories');

        final cats = _parseCategories(categoryRows);
        final items = _parseMenu(menuRows);
        final tops = _parseToppings(toppingRows);

        debugInfo = 'Sheet ID: ${sheetId.substring(0, 8)}...\n'
            'Menu CSV: ${menuRows.length} rows (hdr: ${menuRows.isNotEmpty ? menuRows[0].length : 0} cols)\n'
            'Categories CSV: ${categoryRows.length} rows\n'
            'Toppings CSV: ${toppingRows.length} rows\n'
            'Parsed: ${items.length} items, ${cats.length} cats, ${tops.length} tops\n'
            'Raw: $_lastRawPreview';

        lastSource = 'google';
        return SheetData(
          categories: cats,
          menuItems: items,
          toppings: tops,
          source: 'google',
        );
      } catch (e) {
        lastError = 'Google: $e';
        debugInfo = 'Google failed: $e\nSheet ID: $sheetId';
      }
    } else {
      debugInfo = 'Sheet ID empty or starts with http: "$sheetId"';
    }

    // Try 2: GitHub JSON
    try {
      final data = await _fetchFromUrl(_githubJsonUrl);
      lastSource = 'github';
      return SheetData(
        categories: data.categories,
        menuItems: data.menuItems,
        toppings: data.toppings,
        source: 'github',
      );
    } catch (e) {
      lastError = '$lastError | GitHub: $e';
    }

    // Try 3: Bundled asset (always works)
    try {
      final data = await _fetchFromBundledAsset();
      lastSource = 'bundled';
      return SheetData(
        categories: data.categories,
        menuItems: data.menuItems,
        toppings: data.toppings,
        source: 'bundled',
      );
    } catch (e) {
      lastError = '$lastError | Bundled: $e';
      throw Exception(lastError);
    }
  }

  static Future<SheetData> _fetchFromUrl(String url) async {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'JensPizzeria/3.0',
    }).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return _parseJsonData(response.body);
  }

  static Future<SheetData> _fetchFromBundledAsset() async {
    final jsonStr = await rootBundle.loadString('assets/menu_data.json');
    return _parseJsonData(jsonStr);
  }

  static SheetData _parseJsonData(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

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
      key: _str(map['category'] ?? map['key']),
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
      category: _strOrFallback(map['category'], 'all'),
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
