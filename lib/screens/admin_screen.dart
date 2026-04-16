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
      length: 4,
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
            labelStyle: TextStyle(fontSize: 12),
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'Menu'),
              Tab(icon: Icon(Icons.add_circle_outline, size: 20), text: 'Toppings'),
              Tab(icon: Icon(Icons.discount, size: 20), text: 'Discounts'),
              Tab(icon: Icon(Icons.settings, size: 20), text: 'Settings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MenuItemsTab(),
            _ToppingsTab(),
            _DiscountsTab(),
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
    final categories = menu.categories;

    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('No menu items yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final cat = menu.categoryFor(item.type);
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.restaurant,
                      color: item.isActive ? Colors.deepOrange : Colors.grey,
                    ),
                    title: Text('${item.name} / ${item.nameThai}'),
                    subtitle: Text(
                        '${item.price.toInt()} THB - ${cat?.label ?? item.type} - ${item.isActive ? "Active" : "Inactive"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(context, menu, index, item, categories),
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
        onPressed: () => _showAddDialog(context, menu, categories),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context, MenuProvider menu, List categories) {
    final nameCtrl = TextEditingController();
    final nameThaiCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String type = categories.isNotEmpty ? categories.first.key : 'pizza';

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
                items: categories
                    .map<DropdownMenuItem<String>>((c) =>
                        DropdownMenuItem(value: c.key, child: Text(c.label)))
                    .toList(),
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

  void _showEditDialog(BuildContext context, MenuProvider menu, int index, MenuItem item, List categories) {
    final nameCtrl = TextEditingController(text: item.name);
    final nameThaiCtrl = TextEditingController(text: item.nameThai);
    final priceCtrl = TextEditingController(text: item.price.toString());
    String type = item.type;
    bool isActive = item.isActive;

    // Make sure type is valid
    if (!categories.any((c) => c.key == type)) {
      type = categories.isNotEmpty ? categories.first.key : 'pizza';
    }

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
                items: categories
                    .map<DropdownMenuItem<String>>((c) =>
                        DropdownMenuItem(value: c.key, child: Text(c.label)))
                    .toList(),
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
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final menu = context.read<MenuProvider>();
    final cart = context.read<CartProvider>();
    for (final cat in menu.categories) {
      final discount = cart.categoryDiscounts[cat.key] ?? cat.discount;
      _controllers[cat.key] = TextEditingController(text: discount.toInt().toString());
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final categories = menu.categories;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Discount Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('These discounts are managed via Google Sheets when synced.\nLocal changes here will be overwritten on next sync.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          for (final cat in categories) ...[
            TextField(
              controller: _controllers[cat.key] ??
                  (_controllers[cat.key] = TextEditingController(text: cat.discount.toInt().toString())),
              decoration: InputDecoration(
                labelText: '${cat.label} Discount (THB per item)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: () {
              final cart = context.read<CartProvider>();
              final discounts = <String, double>{};
              for (final cat in categories) {
                final ctrl = _controllers[cat.key];
                discounts[cat.key] = double.tryParse(ctrl?.text ?? '') ?? cat.discount;
              }
              cart.setCategoryDiscounts(discounts);
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

// ============ SETTINGS TAB ============
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _lineCtrl;
  late TextEditingController _promptPayCtrl;
  late TextEditingController _sheetIdCtrl;
  late int _openHour;
  late int _closeHour;
  bool _syncing = false;

  static const _allHours = [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];

  String _hourLabel(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    final menu = context.read<MenuProvider>();
    _lineCtrl = TextEditingController(text: profile.lineDeepLink);
    _promptPayCtrl = TextEditingController(text: profile.promptPayId);
    _sheetIdCtrl = TextEditingController(text: menu.sheetId);
    _openHour = profile.openHour;
    _closeHour = profile.closeHour;
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _promptPayCtrl.dispose();
    _sheetIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncSheet() async {
    final menu = context.read<MenuProvider>();
    final id = _sheetIdCtrl.text.trim();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Google Sheet ID first')),
      );
      return;
    }

    setState(() => _syncing = true);
    await menu.saveSheetId(id);
    final success = await menu.syncFromSheet();
    if (mounted) {
      setState(() => _syncing = false);
      final msg = success
          ? 'Sync OK! ${menu.allItems.length} items, ${menu.categories.length} categories loaded.'
          : 'Sync failed: ${menu.lastSyncError}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Google Sheet Sync
        const Text('Google Sheet Sync', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Enter your Google Sheet ID to sync menu, toppings, categories and discounts.\n'
          'The sheet must be shared as "Anyone with the link can view".',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sheetIdCtrl,
          decoration: const InputDecoration(
            labelText: 'Google Sheet ID or URL',
            hintText: 'Paste the full Google Sheet link here',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _syncing ? null : _syncSheet,
          icon: _syncing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sync),
          label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        const SizedBox(height: 32),

        // Opening Hours
        const Text('Opening Hours', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Set the hours customers can choose for pickup/delivery',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Open', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _openHour,
                        isExpanded: true,
                        items: _allHours
                            .where((h) => h < _closeHour)
                            .map((h) => DropdownMenuItem(value: h, child: Text(_hourLabel(h))))
                            .toList(),
                        onChanged: (v) => setState(() => _openHour = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Close', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _closeHour,
                        isExpanded: true,
                        items: _allHours
                            .where((h) => h > _openHour)
                            .map((h) => DropdownMenuItem(value: h, child: Text(_hourLabel(h))))
                            .toList(),
                        onChanged: (v) => setState(() => _closeHour = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Hours shown to customers: ${_hourLabel(_openHour)} - ${_hourLabel(_closeHour)}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
        ElevatedButton(
          onPressed: () async {
            final profile = context.read<ProfileProvider>();
            final menu = context.read<MenuProvider>();
            await profile.saveLineConfig(_lineCtrl.text.trim());
            await profile.savePromptPayId(_promptPayCtrl.text.trim());
            await profile.saveOpeningHours(_openHour, _closeHour);
            await menu.saveSheetId(_sheetIdCtrl.text.trim());
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
    );
  }
}
