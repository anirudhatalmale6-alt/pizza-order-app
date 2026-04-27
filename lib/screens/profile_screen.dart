import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/platform_helper.dart';
import 'menu_screen.dart';
import 'renewal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _renewalDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRenewalWindow();
    });
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
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Exit / ออก',
              onPressed: () => exitApp(),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
