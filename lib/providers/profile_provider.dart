import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';

class ProfileProvider extends ChangeNotifier {
  late Box<Customer> _customerBox;
  Customer? _currentCustomer;
  int? _currentCustomerIndex;
  String _lineDeepLink = '';
  String _promptPayId = '';
  int _openHour = 11;
  int _closeHour = 16;

  String get customerName => _currentCustomer?.name ?? '';
  String get businessName => _currentCustomer?.businessName ?? '';
  String get lineDeepLink => _lineDeepLink;
  String get promptPayId => _promptPayId;
  int get openHour => _openHour;
  int get closeHour => _closeHour;
  List<int> get availableHours =>
      List.generate(_closeHour - _openHour + 1, (i) => _openHour + i);
  bool get isCustomerSelected => _currentCustomer != null;

  List<Customer> get customers => _customerBox.values.toList();

  Future<void> init() async {
    _customerBox = await Hive.openBox<Customer>('customers');
    final prefs = await SharedPreferences.getInstance();
    _lineDeepLink = prefs.getString('lineDeepLink') ?? '';
    _promptPayId = prefs.getString('promptPayId') ?? '0814726644';
    _openHour = prefs.getInt('openHour') ?? 11;
    _closeHour = prefs.getInt('closeHour') ?? 16;
    notifyListeners();
  }

  Future<Customer> addCustomer(String name, String business) async {
    final customer = Customer(name: name, businessName: business);
    await _customerBox.add(customer);
    _currentCustomer = customer;
    _currentCustomerIndex = _customerBox.length - 1;
    notifyListeners();
    return customer;
  }

  void selectCustomer(int index) {
    _currentCustomer = _customerBox.getAt(index);
    _currentCustomerIndex = index;
    notifyListeners();
  }

  Future<void> updateCustomer(int index, String name, String business) async {
    final customer = _customerBox.getAt(index);
    if (customer != null) {
      customer.name = name;
      customer.businessName = business;
      await customer.save();
      if (_currentCustomerIndex == index) {
        _currentCustomer = customer;
      }
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(int index) async {
    await _customerBox.deleteAt(index);
    if (_currentCustomerIndex == index) {
      _currentCustomer = null;
      _currentCustomerIndex = null;
    }
    notifyListeners();
  }

  void clearSelection() {
    _currentCustomer = null;
    _currentCustomerIndex = null;
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

  Future<void> saveOpeningHours(int open, int close) async {
    final prefs = await SharedPreferences.getInstance();
    _openHour = open;
    _closeHour = close;
    await prefs.setInt('openHour', open);
    await prefs.setInt('closeHour', close);
    notifyListeners();
  }
}
