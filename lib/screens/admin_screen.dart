import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _settingsKey = GlobalKey<_SettingsTabState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin / ตั้งค่า'),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
      ),
      body: _SettingsTab(key: _settingsKey),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              await _settingsKey.currentState?._saveAll();
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save and Exit Settings', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({super.key});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _sheetIdCtrl;
  late TextEditingController _appNameCtrl;
  late TextEditingController _sellerNameCtrl;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    final menu = context.read<MenuProvider>();
    _sheetIdCtrl = TextEditingController(text: menu.sheetId);
    _appNameCtrl = TextEditingController(text: profile.appName);
    _sellerNameCtrl = TextEditingController(text: profile.sellerName);
  }

  @override
  void dispose() {
    _sheetIdCtrl.dispose();
    _appNameCtrl.dispose();
    _sellerNameCtrl.dispose();
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
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Sync OK!'),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(menu.lastSyncError.isNotEmpty
                  ? menu.lastSyncError
                  : '${menu.allItems.length} menu items\n${menu.categories.length} categories'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sync Result'),
            content: SingleChildScrollView(
              child: SelectableText(menu.lastSyncError.isEmpty
                  ? 'Unknown error'
                  : menu.lastSyncError),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Seller Name
        const Text('Seller Name / ชื่อผู้ขาย', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _sellerNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Seller Name',
            hintText: 'e.g., John, Somchai',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 32),

        // Google Sheet Sync
        const Text('Google Sheet Sync', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Enter your Google Sheet ID to sync menu, options, categories and discounts.\n'
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
          maxLines: 5,
          minLines: 3,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final id = _sheetIdCtrl.text.trim();
                  if (id.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No Sheet ID entered')),
                    );
                    return;
                  }
                  final sheetId = id.startsWith('http') ? id : 'https://docs.google.com/spreadsheets/d/$id';
                  launchUrl(Uri.parse(sheetId), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Sheet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveAll() async {
    final profile = context.read<ProfileProvider>();
    final menu = context.read<MenuProvider>();
    await profile.saveSellerName(_sellerNameCtrl.text.trim());
    await profile.saveAppName(_appNameCtrl.text.trim());
    await menu.saveSheetId(_sheetIdCtrl.text.trim());
  }
}
