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

Color colorFromString(String name) {
  switch (name.toLowerCase().replaceAll(' ', '')) {
    case 'deeporange':
      return Colors.deepOrange;
    case 'blue':
      return Colors.blue;
    case 'lightblue':
      return Colors.lightBlue;
    case 'green':
      return Colors.green;
    case 'lightgreen':
      return Colors.lightGreen;
    case 'red':
      return Colors.red;
    case 'purple':
      return Colors.purple;
    case 'deeppurple':
      return Colors.deepPurple;
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
    case 'yellow':
      return Colors.yellow.shade700;
    case 'lime':
      return Colors.lime.shade700;
    case 'grey':
    case 'gray':
      return Colors.grey;
    case 'bluegrey':
    case 'bluegray':
      return Colors.blueGrey;
    default:
      if (name.startsWith('#') && name.length == 7) {
        final hex = int.tryParse(name.substring(1), radix: 16);
        if (hex != null) return Color(0xFF000000 | hex);
      }
      return Colors.deepOrange;
  }
}

// ============ CATEGORY SELECTION SCREEN (Main Menu) ============

class MenuScreen extends StatefulWidget {
  final String? greeting;
  const MenuScreen({super.key, this.greeting});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const _adminPassword = 'tg308111';

  @override
  void initState() {
    super.initState();
    // Sync menu from Google Sheet every time a staff member starts an order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().syncFromSheet();
      if (widget.greeting != null && widget.greeting!.isNotEmpty) {
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
      }
    });
  }

  void _openAdmin() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Access'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter password',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            if (val == _adminPassword) {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text == _adminPassword) {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrong password'), duration: Duration(seconds: 2)),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          icon: const Icon(Icons.arrow_back),
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
        title: Column(
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
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 20, color: Colors.white.withOpacity(0.7)),
            tooltip: 'Admin',
            onPressed: _openAdmin,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Sync status banner
            if (!menu.syncedFromSheet && menu.lastSyncError.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final color = colorFromString(cat.color);
                  final icon = iconFromString(cat.icon);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryItemsScreen(category: cat),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3), width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 40),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.label,
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                                  if (cat.labelThai.isNotEmpty)
                                    Text(cat.labelThai,
                                        style: TextStyle(fontSize: 15, color: color.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: color, size: 28),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Cancel Order? / ยกเลิกออเดอร์?'),
                                content: const Text('Clear all items from the cart?\nล้างรายการทั้งหมด?'),
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
                                    child: const Text('Yes / ใช่'),
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
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel Order\nยกเลิกออเดอร์',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OrderSummaryScreen()),
                          ),
                          icon: const Icon(Icons.receipt_long),
                          label: Text('View Order (${cart.items.length})\nดูออเดอร์',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ============ CATEGORY ITEMS SCREEN ============

class CategoryItemsScreen extends StatelessWidget {
  final CategoryConfig category;
  const CategoryItemsScreen({super.key, required this.category});

  void _addItemToCart(BuildContext context, MenuItem item) async {
    final cart = context.read<CartProvider>();
    final toppings = context.read<MenuProvider>().toppingsForItem(item.name, category.key);
    if (toppings.isNotEmpty) {
      final selected = await showDialog<List<SelectedTopping>>(
        context: context,
        builder: (_) => ToppingDialog(availableToppings: toppings, categoryLabel: item.name),
      );
      if (selected != null) {
        cart.addItem(CartItem(
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
      return;
    }
    cart.addItem(CartItem(
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

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final items = menu.itemsForCategory(category.key);
    final color = colorFromString(category.color);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(iconFromString(category.icon), size: 24),
            const SizedBox(width: 8),
            Text('${category.label} / ${category.labelThai}'),
          ],
        ),
        backgroundColor: color,
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
      body: items.isEmpty
          ? const Center(
              child: Text('No items in this category\nยังไม่มีรายการในหมวดนี้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _MenuItemCard(
                  item: item,
                  category: category,
                  onAdd: () => _addItemToCart(context, item),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Return to Menu\nกลับไปเมนู',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ SHARED WIDGETS ============

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final CategoryConfig category;
  final VoidCallback onAdd;
  const _MenuItemCard({required this.item, required this.category, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final color = colorFromString(category.color);
    final icon = iconFromString(category.icon);

    final hasImage = item.imageUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasImage)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 8),
                          child: Icon(icon, color: color, size: 22),
                        ),
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
                      Text('${item.price.toInt()} THB',
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
          ],
        ),
      ),
    );
  }
}
