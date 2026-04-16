import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/category_config.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/topping_dialog.dart';
import 'order_summary_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';

// Map icon name strings to IconData
IconData iconFromString(String name) {
  switch (name.toLowerCase().trim()) {
    case '':
      return Icons.restaurant;
    case 'local_pizza':
      return Icons.local_pizza;
    case 'local_drink':
      return Icons.local_drink;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'restaurant':
      return Icons.restaurant;
    case 'fastfood':
      return Icons.fastfood;
    case 'icecream':
      return Icons.icecream;
    case 'cake':
      return Icons.cake;
    case 'lunch_dining':
      return Icons.lunch_dining;
    case 'set_meal':
      return Icons.set_meal;
    case 'local_bar':
      return Icons.local_bar;
    case 'bakery_dining':
      return Icons.bakery_dining;
    case 'ramen_dining':
      return Icons.ramen_dining;
    case 'cookie':
      return Icons.cookie;
    default:
      return Icons.restaurant;
  }
}

// Map color name strings to Color
Color colorFromString(String name) {
  switch (name.toLowerCase()) {
    case 'deepOrange':
      return Colors.deepOrange;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'red':
      return Colors.red;
    case 'purple':
      return Colors.purple;
    case 'teal':
      return Colors.teal;
    case 'amber':
      return Colors.amber;
    case 'brown':
      return Colors.brown;
    case 'pink':
      return Colors.pink;
    case 'indigo':
      return Colors.indigo;
    case 'orange':
      return Colors.orange;
    case 'cyan':
      return Colors.cyan;
    default:
      return Colors.deepOrange;
  }
}

class MenuScreen extends StatefulWidget {
  final String? greeting;
  const MenuScreen({super.key, this.greeting});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _logoTapCount = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    if (widget.greeting != null && widget.greeting!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hello ${widget.greeting}! / สวัสดี ${widget.greeting}!',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

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

  void _addItemToCart(MenuItem item, CategoryConfig category) async {
    if (category.hasToppings) {
      final toppings = context.read<MenuProvider>().toppings;
      final selected = await showDialog<List<SelectedTopping>>(
        context: context,
        builder: (_) => ToppingDialog(availableToppings: toppings),
      );
      if (selected != null && mounted) {
        context.read<CartProvider>().addItem(CartItem(
          productName: item.name,
          productNameThai: item.nameThai,
          productType: category.key,
          basePrice: item.price,
          toppings: selected,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added / เพิ่ม${item.nameThai}แล้ว'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      context.read<CartProvider>().addItem(CartItem(
        productName: item.name,
        productNameThai: item.nameThai,
        productType: category.key,
        basePrice: item.price,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added / เพิ่ม${item.nameThai}แล้ว'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final profile = context.watch<ProfileProvider>();
    final categories = menu.categories;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.people),
          tooltip: 'Switch staff',
          onPressed: () {
            profile.clearSelection();
            cart.clear();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        title: GestureDetector(
          onTap: _onLogoTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Menu / เมนู', style: TextStyle(fontSize: 18)),
              if (profile.customerName.isNotEmpty)
                Text(
                  profile.customerName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel order / ยกเลิก',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel Order? / ยกเลิกออเดอร์?'),
                    content: const Text(
                        'Clear all items from the cart?\nล้างรายการทั้งหมด?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No / ไม่'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Yes, Cancel / ใช่ ยกเลิก'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  cart.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order cancelled / ยกเลิกออเดอร์แล้ว'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
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
          // Sync status banner
          if (!menu.syncedFromSheet && menu.lastSyncError.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Offline mode - using cached menu',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ),
                ],
              ),
            ),
          for (int ci = 0; ci < categories.length; ci++) ...[
            if (ci > 0) const SizedBox(height: 24),
            _SectionHeader(
              icon: iconFromString(categories[ci].icon),
              title: '${categories[ci].label} / ${categories[ci].labelThai}',
              color: colorFromString(categories[ci].color),
            ),
            ...menu.itemsForCategory(categories[ci].key).map((item) =>
                _MenuItemCard(
                  item: item,
                  category: categories[ci],
                  onAdd: () => _addItemToCart(item, categories[ci]),
                )),
          ],
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
  final Color color;
  const _SectionHeader({required this.icon, required this.title, this.color = Colors.deepOrange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final CategoryConfig category;
  final VoidCallback onAdd;
  const _MenuItemCard({required this.item, required this.category, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final color = colorFromString(category.color);
    final icon = iconFromString(category.icon);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nameThai,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      Text(item.name,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('   ${item.price.toInt()} THB',
                    style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
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
