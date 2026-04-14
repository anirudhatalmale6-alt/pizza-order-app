import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  String _customerName = '';
  String _businessName = '';
  String _lineDeepLink = '';
  String _promptPayId = '';
  bool _isProfileSet = false;

  String get customerName => _customerName;
  String get businessName => _businessName;
  String get lineDeepLink => _lineDeepLink;
  String get promptPayId => _promptPayId;
  bool get isProfileSet => _isProfileSet;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customerName = prefs.getString('customerName') ?? '';
    _businessName = prefs.getString('businessName') ?? '';
    _lineDeepLink = prefs.getString('lineDeepLink') ?? '';
    _promptPayId = prefs.getString('promptPayId') ?? '';
    _isProfileSet = _customerName.isNotEmpty;
    notifyListeners();
  }

  Future<void> saveProfile(String name, String business) async {
    final prefs = await SharedPreferences.getInstance();
    _customerName = name;
    _businessName = business;
    _isProfileSet = true;
    await prefs.setString('customerName', name);
    await prefs.setString('businessName', business);
    notifyListeners();
  }

  Future<void> saveLineConfig(String deepLink) async {
    final prefs = await SharedPreferences.getInstance();
    _lineDeepLink = deepLink;
    await prefs.setString('lineDeepLink', deepLink);
    notifyListeners();
  }

  Future<void> savePromptPayId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _promptPayId = id;
    await prefs.setString('promptPayId', id);
    notifyListeners();
  }
}
