import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/topping_dialog.dart';
import 'order_summary_screen.dart';
import 'admin_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _logoTapCount = 0;
  DateTime? _lastTap;

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 3) {
      _logoTapCount = 0;
    }
    _lastTap = now;
    _logoTapCount++;
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
    }
  }

  void _addPizzaToCart(MenuItem pizza) async {
    final toppings = context.read<MenuProvider>().toppings;
    final selected = await showDialog<List<SelectedTopping>>(
      context: context,
      builder: (_) => ToppingDialog(availableToppings: toppings),
    );
    if (selected != null && mounted) {
      context.read<CartProvider>().addItem(CartItem(
        productName: pizza.name,
        productNameThai: pizza.nameThai,
        productType: 'pizza',
        basePrice: pizza.price,
        toppings: selected,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pizza.name} added / เพิ่ม${pizza.nameThai}แล้ว'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _addDrinkToCart(MenuItem drink) {
    context.read<CartProvider>().addItem(CartItem(
      productName: drink.name,
      productNameThai: drink.nameThai,
      productType: 'drink',
      basePrice: drink.price,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drink.name} added / เพิ่ม${drink.nameThai}แล้ว'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onLogoTap,
          child: const Text('Menu / เมนู'),
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: cart.isEmpty
                    ? null
                    : () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const OrderSummaryScreen())),
              ),
              if (!cart.isEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.items.length}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pizza Section
          const _SectionHeader(
            icon: Icons.local_pizza,
            title: 'Pizza / พิซซ่า',
          ),
          ...menu.pizzas.map((pizza) => _PizzaCard(
                pizza: pizza,
                onAdd: () => _addPizzaToCart(pizza),
              )),

          const SizedBox(height: 24),

          // Drinks Section
          const _SectionHeader(
            icon: Icons.local_drink,
            title: 'Drinks / เครื่องดื่ม',
          ),
          ...menu.drinks.map((drink) => _DrinkCard(
                drink: drink,
                onAdd: () => _addDrinkToCart(drink),
              )),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderSummaryScreen()),
              ),
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.receipt_long),
              label: Text(
                  'View Order (${cart.items.length}) / ดูออเดอร์'),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepOrange, size: 28),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PizzaCard extends StatelessWidget {
  final MenuItem pizza;
  final VoidCallback onAdd;
  const _PizzaCard({required this.pizza, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_pizza, color: Colors.deepOrange, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${pizza.nameThai} / ${pizza.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('   ${pizza.price.toInt()} THB',
                    style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text('+ Add / เพิ่ม'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DrinkCard extends StatelessWidget {
  final MenuItem drink;
  final VoidCallback onAdd;
  const _DrinkCard({required this.drink, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_drink, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${drink.nameThai} / ${drink.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('   ${drink.price.toInt()} THB',
                    style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text('+ Add / เพิ่ม'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
