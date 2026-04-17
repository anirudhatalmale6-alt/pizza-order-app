import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'menu_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _goToMenu(BuildContext context, String customerName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(greeting: customerName)),
    );
  }

  void _showNewCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final businessCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('New Staff Member / พนักงานใหม่',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Staff Name / ชื่อพนักงาน',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Guest House / ชื่อที่พัก',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(
                  controller: businessCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter guest house name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Staff / แก้ไขพนักงาน',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Staff Name / ชื่อพนักงาน',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Guest House / ชื่อที่พัก',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(
                  controller: businessCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter guest house name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
                      children: [
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
    final customers = profile.customers;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Jen's Pizzeria"),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Exit / ออก',
              onPressed: () => SystemNavigator.pop(),
            ),
          ],
        ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Staff Member / พนักงาน',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your name to start taking orders\nเลือกชื่อเพื่อเริ่มรับออเดอร์',
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
                        const Text('No staff members yet\nยังไม่มีพนักงาน',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _showNewCustomerDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('New Staff Member / พนักงานใหม่',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
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
