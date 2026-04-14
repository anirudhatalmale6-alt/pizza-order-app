import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin / ตั้งค่า'),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: false,
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 11),
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu, size: 18), text: 'Menu'),
              Tab(icon: Icon(Icons.add_circle_outline, size: 18), text: 'Toppings'),
              Tab(icon: Icon(Icons.discount, size: 18), text: 'Discounts'),
              Tab(icon: Icon(Icons.person, size: 18), text: 'Profile'),
              Tab(icon: Icon(Icons.settings, size: 18), text: 'Settings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MenuItemsTab(),
            _ToppingsTab(),
            _DiscountsTab(),
            _ProfileTab(),
            _SettingsTab(),
          ],
        ),
      ),
    );
  }
}

// ============ MENU ITEMS TAB ============
class _MenuItemsTab extends StatelessWidget {
  const _MenuItemsTab();

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final items = menu.allItems;

    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('No menu items yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item.type == 'pizza' ? Icons.local_pizza : Icons.local_drink,
                      color: item.isActive ? Colors.deepOrange : Colors.grey,
                    ),
                    title: Text('${item.name} / ${item.nameThai}'),
                    subtitle: Text(
                        '${item.price.toInt()} THB - ${item.type} - ${item.isActive ? "Active" : "Inactive"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(context, menu, index, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => menu.deleteMenuItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, menu),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context, MenuProvider menu) {
    final nameCtrl = TextEditingController();
    final nameThaiCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String type = 'pizza';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name (English)')),
              TextField(
                  controller: nameThaiCtrl,
                  decoration: const InputDecoration(labelText: 'Name (Thai)')),
              TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (THB)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'pizza', child: Text('Pizza')),
                  DropdownMenuItem(value: 'drink', child: Text('Drink')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                  menu.addMenuItem(MenuItem(
                    name: nameCtrl.text.trim(),
                    nameThai: nameThaiCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text) ?? 0,
                    type: type,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, MenuProvider menu, int index, MenuItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final nameThaiCtrl = TextEditingController(text: item.nameThai);
    final priceCtrl = TextEditingController(text: item.price.toString());
    String type = item.type;
    bool isActive = item.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name (English)')),
              TextField(
                  controller: nameThaiCtrl,
                  decoration: const InputDecoration(labelText: 'Name (Thai)')),
              TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (THB)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'pizza', child: Text('Pizza')),
                  DropdownMenuItem(value: 'drink', child: Text('Drink')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                menu.updateMenuItem(index, MenuItem(
                  name: nameCtrl.text.trim(),
                  nameThai: nameThaiCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  type: type,
                  isActive: isActive,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ TOPPINGS TAB ============
class _ToppingsTab extends StatelessWidget {
  const _ToppingsTab();

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final items = menu.allToppings;

    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('No toppings yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.restaurant,
                        color: item.isActive ? Colors.deepOrange : Colors.grey),
                    title: Text('${item.name} / ${item.nameThai}'),
                    subtitle: Text(
                        '+${item.price.toInt()} THB - ${item.isActive ? "Active" : "Inactive"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(context, menu, index, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => menu.deleteTopping(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, menu),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context, MenuProvider menu) {
    final nameCtrl = TextEditingController();
    final nameThaiCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Topping'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name (English)')),
            TextField(
                controller: nameThaiCtrl,
                decoration: const InputDecoration(labelText: 'Name (Thai)')),
            TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price (THB)'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                menu.addTopping(ToppingItem(
                  name: nameCtrl.text.trim(),
                  nameThai: nameThaiCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 0,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, MenuProvider menu, int index, ToppingItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final nameThaiCtrl = TextEditingController(text: item.nameThai);
    final priceCtrl = TextEditingController(text: item.price.toString());
    bool isActive = item.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Topping'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name (English)')),
              TextField(
                  controller: nameThaiCtrl,
                  decoration: const InputDecoration(labelText: 'Name (Thai)')),
              TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (THB)'),
                  keyboardType: TextInputType.number),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                menu.updateTopping(index, ToppingItem(
                  name: nameCtrl.text.trim(),
                  nameThai: nameThaiCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  isActive: isActive,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ DISCOUNTS TAB ============
class _DiscountsTab extends StatefulWidget {
  const _DiscountsTab();

  @override
  State<_DiscountsTab> createState() => _DiscountsTabState();
}

class _DiscountsTabState extends State<_DiscountsTab> {
  late TextEditingController _pizzaDiscountCtrl;
  late TextEditingController _drinkDiscountCtrl;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _pizzaDiscountCtrl = TextEditingController(text: cart.pizzaDiscount.toInt().toString());
    _drinkDiscountCtrl = TextEditingController(text: cart.drinkDiscount.toInt().toString());
  }

  @override
  void dispose() {
    _pizzaDiscountCtrl.dispose();
    _drinkDiscountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Discount Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _pizzaDiscountCtrl,
            decoration: const InputDecoration(
              labelText: 'Pizza Discount (THB per pizza)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _drinkDiscountCtrl,
            decoration: const InputDecoration(
              labelText: 'Drink Discount (THB per drink)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final cart = context.read<CartProvider>();
              cart.pizzaDiscount = double.tryParse(_pizzaDiscountCtrl.text) ?? 20;
              cart.drinkDiscount = double.tryParse(_drinkDiscountCtrl.text) ?? 5;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Discounts saved!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Discounts'),
          ),
        ],
      ),
    );
  }
}

// ============ PROFILE TAB ============
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _businessCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _nameCtrl = TextEditingController(text: profile.customerName);
    _businessCtrl = TextEditingController(text: profile.businessName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Customer Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Edit the customer name and business that appear on orders.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text('Customer Name / ชื่อลูกค้า',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Business Name / ชื่อธุรกิจ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _businessCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter business name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name cannot be empty')),
                );
                return;
              }
              await context
                  .read<ProfileProvider>()
                  .saveProfile(name, _businessCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}

// ============ SETTINGS TAB ============
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _lineCtrl;
  late TextEditingController _promptPayCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _lineCtrl = TextEditingController(text: profile.lineDeepLink);
    _promptPayCtrl = TextEditingController(text: profile.promptPayId);
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _promptPayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('LINE Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _lineCtrl,
            decoration: const InputDecoration(
              labelText: 'LINE Deep Link / URL',
              hintText: 'e.g., https://line.me/R/ti/p/@yourlineID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('PromptPay Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _promptPayCtrl,
            decoration: const InputDecoration(
              labelText: 'PromptPay ID',
              hintText: 'Phone number or National ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your phone number (e.g., 0812345678) or\nNational ID (13 digits) for QR payment',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final profile = context.read<ProfileProvider>();
              await profile.saveLineConfig(_lineCtrl.text.trim());
              await profile.savePromptPayId(_promptPayCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
