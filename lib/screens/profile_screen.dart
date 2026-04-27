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

  void _goToMenu(BuildContext context, String customerName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(greeting: customerName)),
    );
  }

  void _showNewCustomerDialog(BuildContext context) {
    final profile = context.read<ProfileProvider>();
    final nameCtrl = TextEditingController();
    final businessCtrl = TextEditingController(text: profile.appName);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('New Seller / ผู้ขายใหม่',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name / ชื่อ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: businessCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Name / ชื่อธุรกิจ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel / ยกเลิก'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        await context
                            .read<ProfileProvider>()
                            .addCustomer(name, businessCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) _goToMenu(context, name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save / บันทึก'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCustomerDialog(
      BuildContext context, int index, String name, String business) {
    final nameCtrl = TextEditingController(text: name);
    final businessCtrl = TextEditingController(text: business);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Seller / แก้ไขผู้ขาย',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name / ชื่อ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: businessCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Name / ชื่อธุรกิจ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        await context
                            .read<ProfileProvider>()
                            .deleteCustomer(index);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Delete / ลบ',
                          style: TextStyle(color: Colors.red)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel / ยกเลิก'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        if (newName.isEmpty) return;
                        await context.read<ProfileProvider>().updateCustomer(
                            index, newName, businessCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save / บันทึก'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final menu = context.watch<MenuProvider>();
    final customers = profile.customers;

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
      body: Column(
        children: [
          const SizedBox(height: 16),
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
            const SizedBox(height: 8),
          ],
          if (menu.logoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                menu.logoUrl,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/logo.jpg', height: 100, fit: BoxFit.contain),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/logo.jpg', height: 100, fit: BoxFit.contain),
            ),
          const SizedBox(height: 12),
          const Text(
            'Seller / ผู้ขาย',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your name to start\nเลือกชื่อเพื่อเริ่ม',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No sellers yet\nยังไม่มีผู้ขาย',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            profile.selectCustomer(index);
                            _goToMenu(context, customer.name);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.deepOrange,
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      if (customer.businessName.isNotEmpty)
                                        Text(
                                          customer.businessName,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 20, color: Colors.grey),
                                  onPressed: () => _showEditCustomerDialog(
                                    context,
                                    index,
                                    customer.name,
                                    customer.businessName,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showNewCustomerDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('New Seller / ผู้ขายใหม่',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
