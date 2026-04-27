import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/platform_helper.dart';
import 'admin_screen.dart';
import 'menu_screen.dart';
import 'renewal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _adminPassword = 'tg308111';
  bool _renewalDialogShown = false;
  late TextEditingController _sellerNameCtrl;

  @override
  void initState() {
    super.initState();
    _sellerNameCtrl = TextEditingController(
      text: context.read<ProfileProvider>().sellerName,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRenewalWindow();
    });
  }

  @override
  void dispose() {
    _sellerNameCtrl.dispose();
    super.dispose();
  }

  void _checkRenewalWindow() {
    final menu = context.read<MenuProvider>();
    if (!menu.isExpired && menu.isInRenewalWindow && !_renewalDialogShown) {
      _renewalDialogShown = true;
      _showRenewalDialog();
    }
  }

  void _showRenewalDialog() {
    final menu = context.read<MenuProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('Subscription Expiring\nใกล้หมดอายุ')),
          ],
        ),
        content: Text(
          'Your subscription expires in ${menu.daysUntilExpiry} day(s).\n'
          'Please renew to avoid interruption.\n\n'
          'สมัครสมาชิกของคุณจะหมดอายุในอีก ${menu.daysUntilExpiry} วัน\n'
          'กรุณาต่ออายุก่อนหมด',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later / ภายหลัง'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RenewalScreen(canContinue: true),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Renew Now / ต่ออายุ'),
          ),
        ],
      ),
    );
  }

  void _showNameDialog() {
    _sellerNameCtrl.text = context.read<ProfileProvider>().sellerName;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Seller Name / ชื่อผู้ขาย'),
        content: TextField(
          controller: _sellerNameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name / ใส่ชื่อของคุณ',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context.read<ProfileProvider>().saveSellerName(val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          if (context.read<ProfileProvider>().sellerName.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ElevatedButton(
            onPressed: () {
              final name = _sellerNameCtrl.text.trim();
              if (name.isNotEmpty) {
                context.read<ProfileProvider>().saveSellerName(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
    final profile = context.watch<ProfileProvider>();
    final menu = context.watch<MenuProvider>();

    if (menu.isExpired) {
      return const RenewalScreen(canContinue: false);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) exitApp();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile.appName),
          centerTitle: true,
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Admin / ตั้งค่า',
              onPressed: _openAdmin,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (profile.sellerName.isNotEmpty) ...[
                GestureDetector(
                  onTap: _showNameDialog,
                  child: Text(
                    profile.sellerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (menu.restaurantName.isNotEmpty) ...[
                Text(
                  menu.restaurantName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (menu.logoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    menu.logoUrl,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/logo.jpg', height: 120, fit: BoxFit.contain),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/logo.jpg', height: 120, fit: BoxFit.contain),
                ),
              const SizedBox(height: 32),
              if (profile.sellerName.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _showNameDialog,
                      icon: const Icon(Icons.person_add, size: 28),
                      label: const Text('Please Enter Your Name\nกรุณาใส่ชื่อของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MenuScreen()),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 28),
                      label: const Text('New Order / สั่งอาหาร',
                          style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
