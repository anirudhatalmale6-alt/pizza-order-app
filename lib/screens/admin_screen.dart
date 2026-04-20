import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/platform_helper.dart';
import '../utils/platform_image.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin / ตั้งค่า'),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
      ),
      body: const _SettingsTab(),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _lineCtrl;
  late TextEditingController _promptPayCtrl;
  late TextEditingController _sheetIdCtrl;
  late TextEditingController _appNameCtrl;
  late int _openHour;
  late int _closeHour;
  bool _syncing = false;
  String _logoPath = '';
  Uint8List? _logoBytes;

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
    _appNameCtrl = TextEditingController(text: profile.appName);
    _openHour = profile.openHour;
    _closeHour = profile.closeHour;
    _logoPath = profile.logoPath;
    if (kIsWeb && profile.logoBase64.isNotEmpty) {
      _logoBytes = profile.logoBase64Bytes;
    }
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _promptPayCtrl.dispose();
    _sheetIdCtrl.dispose();
    _appNameCtrl.dispose();
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
        // App Name
        const Text('App Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _appNameCtrl,
          decoration: const InputDecoration(
            labelText: 'App Name',
            hintText: "e.g., Jen's Pizzeria",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        // Logo
        const Text('Logo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (kIsWeb && _logoBytes != null && _logoBytes!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_logoBytes!, height: 100, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() { _logoBytes = null; _logoPath = ''; });
              context.read<ProfileProvider>().saveLogoBase64('');
              context.read<ProfileProvider>().saveLogoPath('');
            },
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
          ),
        ] else if (!kIsWeb && _logoPath.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: platformFileImage(_logoPath, height: 100, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() => _logoPath = '');
              context.read<ProfileProvider>().saveLogoPath('');
            },
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                onPressed: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    if (kIsWeb) {
                      final bytes = await image.readAsBytes();
                      final b64 = base64Encode(bytes);
                      setState(() { _logoBytes = bytes; _logoPath = ''; });
                      if (mounted) {
                        await context.read<ProfileProvider>().saveLogoBase64(b64);
                      }
                    } else {
                      final appDir = await getAppDocumentsPath();
                      final saved = await File(image.path).copy('$appDir/logo.png');
                      setState(() => _logoPath = saved.path);
                      if (mounted) {
                        await context.read<ProfileProvider>().saveLogoPath(saved.path);
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                onPressed: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    if (kIsWeb) {
                      final bytes = await image.readAsBytes();
                      final b64 = base64Encode(bytes);
                      setState(() { _logoBytes = bytes; _logoPath = ''; });
                      if (mounted) {
                        await context.read<ProfileProvider>().saveLogoBase64(b64);
                      }
                    } else {
                      final appDir = await getAppDocumentsPath();
                      final saved = await File(image.path).copy('$appDir/logo.png');
                      setState(() => _logoPath = saved.path);
                      if (mounted) {
                        await context.read<ProfileProvider>().saveLogoPath(saved.path);
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

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
          maxLines: 5,
          minLines: 3,
          style: const TextStyle(fontSize: 13),
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
          'Enter your PromptPay account number for payment',
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
            await profile.saveAppName(_appNameCtrl.text.trim());
            await profile.saveLogoPath(_logoPath);
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
