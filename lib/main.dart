import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/customer.dart';
import 'models/menu_item.dart';
import 'providers/cart_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MenuItemAdapter());
  Hive.registerAdapter(ToppingItemAdapter());
  Hive.registerAdapter(CustomerAdapter());

  final menuProvider = MenuProvider();
  await menuProvider.init();

  final profileProvider = ProfileProvider();
  await profileProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: menuProvider),
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const PizzaOrderApp(),
    ),
  );
}

class PizzaOrderApp extends StatelessWidget {
  const PizzaOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pizza Order',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}
