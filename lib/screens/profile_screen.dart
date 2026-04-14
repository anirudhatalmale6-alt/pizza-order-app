import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'menu_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _nameController.text = profile.customerName;
    _businessController.text = profile.businessName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    final business = _businessController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name / กรุณากรอกชื่อ')),
      );
      return;
    }
    await context.read<ProfileProvider>().saveProfile(name, business);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile / กรอกข้อมูล'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.local_pizza, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 24),
            const Text(
              'Welcome! / ยินดีต้อนรับ!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your details to get started\nกรอกข้อมูลเพื่อเริ่มต้น',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text('Customer Name / ชื่อลูกค้า',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter name here',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Business Name / ชื่อธุรกิจ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _businessController,
              decoration: const InputDecoration(
                hintText: 'Enter business name here',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Save & Continue / บันทึกและดำเนินการต่อ'),
            ),
          ],
        ),
      ),
    );
  }
}
