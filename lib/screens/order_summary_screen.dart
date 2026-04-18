import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category_config.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/promptpay_qr.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  File? _paymentScreenshot;
  String _orderType = 'pickup'; // 'pickup' or 'delivery'
  int? _selectedHour; // 11-16
  bool _orderConfirmed = false;
  final _guestNameCtrl = TextEditingController();

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _paymentScreenshot = File(image.path));
    }
  }

  Future<void> _takeScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _paymentScreenshot = File(image.path));
    }
  }

  List<CategoryConfig> _categoriesWithItems() {
    final menu = context.read<MenuProvider>();
    final cart = context.read<CartProvider>();
    final categories = menu.categories;
    // Return only categories that have items in the cart
    return categories.where((c) => cart.countForCategory(c.key) > 0).toList();
  }

  String _buildOrderText() {
    final cart = context.read<CartProvider>();
    final profile = context.read<ProfileProvider>();
    final menu = context.read<MenuProvider>();
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    final sb = StringBuffer();
    sb.writeln('PAID ORDER / ออเดอร์ที่ชำระแล้ว');
    sb.writeln('================================');
    if (_guestNameCtrl.text.trim().isNotEmpty) {
      sb.writeln('Guest / ชื่อผู้สั่ง: ${_guestNameCtrl.text.trim()}');
    }
    sb.writeln('Staff / พนักงาน: ${profile.customerName}');
    if (profile.businessName.isNotEmpty) {
      sb.writeln('Business / ธุรกิจ: ${profile.businessName}');
    }
    final typeText = _orderType == 'pickup'
        ? 'Pickup / รับเอง'
        : 'Delivery / จัดส่ง';
    sb.writeln('Type / ประเภท: $typeText');
    if (_selectedHour != null) {
      final period = _selectedHour! < 12 ? 'AM' : 'PM';
      final display12 = _selectedHour! > 12 ? _selectedHour! - 12 : _selectedHour!;
      sb.writeln('Time / เวลา: ${display12}:00 $period ($_selectedHour:00)');
    }
    sb.writeln();
    sb.writeln('Items / รายการ:');

    for (final item in cart.items) {
      final cat = menu.categoryFor(item.productType);
      final hasToppings = cat?.hasToppings ?? false;
      if (hasToppings && item.toppings.isNotEmpty) {
        final toppingsStr =
            ' (${item.toppings.map((t) => '${t.nameThai} +${t.price.toInt()} / ${t.name} +${t.price.toInt()}').join(', ')})';
        sb.writeln(
            '- ${item.productNameThai} / ${item.productName}$toppingsStr x${item.quantity} → ${item.basePrice.toInt()} +${item.toppingsTotal.toInt()} = ${item.itemTotal.toInt()} THB');
      } else {
        sb.writeln(
            '- ${item.productNameThai} / ${item.productName} x${item.quantity} → ${item.itemTotal.toInt()} THB');
      }
    }

    sb.writeln();
    sb.writeln('ส่วนลด / Discount:');
    for (final cat in _categoriesWithItems()) {
      final count = cart.countForCategory(cat.key);
      final discount = cart.categoryDiscounts[cat.key] ?? 0;
      final total = cart.discountForCategory(cat.key);
      if (discount > 0) {
        sb.writeln(
            '- ${cat.labelThai} ${count} × ${discount.toInt()} / ${count} ${cat.label.toLowerCase()} × ${discount.toInt()} = ${total.toInt()} THB');
      }
    }
    sb.writeln();
    sb.writeln('ยอดรวมสุดท้าย / Final total: ${cart.finalTotal.toInt()} THB');
    sb.writeln();
    sb.writeln('ชำระโดย / Payment via PromptPay QR');
    sb.writeln('เวลา / Time: $now');

    return sb.toString();
  }

  String _buildConfirmText() {
    final cart = context.read<CartProvider>();
    final profile = context.read<ProfileProvider>();
    final menu = context.read<MenuProvider>();

    final sb = StringBuffer();
    sb.writeln('CONFIRM ORDER / ยืนยันออเดอร์');
    sb.writeln('================================');
    if (_guestNameCtrl.text.trim().isNotEmpty) {
      sb.writeln('Guest / ชื่อผู้สั่ง: ${_guestNameCtrl.text.trim()}');
    }
    sb.writeln('Staff / พนักงาน: ${profile.customerName}');
    if (profile.businessName.isNotEmpty) {
      sb.writeln('Business / ธุรกิจ: ${profile.businessName}');
    }
    sb.writeln();

    final typeText = _orderType == 'pickup'
        ? 'Pickup / รับเอง'
        : 'Delivery / จัดส่ง';
    sb.writeln('Type / ประเภท: $typeText');
    if (_selectedHour != null) {
      final period = _selectedHour! < 12 ? 'AM' : 'PM';
      final display12 = _selectedHour! > 12 ? _selectedHour! - 12 : _selectedHour!;
      sb.writeln('Time / เวลา: ${display12}:00 $period ($_selectedHour:00)');
    }
    sb.writeln();

    sb.writeln('Items / รายการ:');
    for (final item in cart.items) {
      final cat = menu.categoryFor(item.productType);
      final hasToppings = cat?.hasToppings ?? false;
      if (hasToppings && item.toppings.isNotEmpty) {
        final toppingsStr = ' + ${item.toppings.map((t) => t.name).join(', ')}';
        sb.writeln('- ${item.productName}$toppingsStr x${item.quantity} = ${item.itemTotal.toInt()} THB');
      } else {
        sb.writeln('- ${item.productName} x${item.quantity} = ${item.itemTotal.toInt()} THB');
      }
    }
    sb.writeln();
    sb.writeln('Total / รวม: ${cart.finalTotal.toInt()} THB');
    sb.writeln('================================');
    sb.writeln('Please confirm this order is OK');
    sb.writeln('กรุณายืนยันว่าออเดอร์ถูกต้อง');

    return sb.toString();
  }

  static const _shareChannel = MethodChannel('com.pizzaorder/share');

  Future<void> _sendConfirmation() async {
    // Just set the state to show warning + send button on the page
    setState(() => _orderConfirmed = true);
  }

  Future<void> _doShareConfirmation() async {
    final confirmText = _buildConfirmText();

    bool sent = false;
    try {
      final result = await _shareChannel.invokeMethod('shareToLine', {'text': confirmText});
      sent = (result == true);
    } catch (_) {}

    if (!sent && mounted) {
      await Clipboard.setData(ClipboardData(text: confirmText));
      await Share.share(confirmText);
    }
  }

  Future<void> _sendToLine() async {
    final orderText = _buildOrderText();

    if (mounted) {
      await Clipboard.setData(ClipboardData(text: orderText));
      bool sent = false;
      try {
        final args = <String, String>{'text': orderText};
        if (_paymentScreenshot != null && _paymentScreenshot!.existsSync()) {
          args['imagePath'] = _paymentScreenshot!.path;
        }
        final result = await _shareChannel.invokeMethod('shareToLine', args);
        sent = (result == true);
      } catch (_) {}
      if (!sent && mounted) {
        // Fallback: use share sheet
        if (_paymentScreenshot != null && _paymentScreenshot!.existsSync()) {
          await Share.shareXFiles(
            [XFile(_paymentScreenshot!.path)],
            text: orderText,
          );
        } else {
          await Share.share(orderText);
        }
      }
    }

    if (!mounted) return;
    context.read<CartProvider>().clear();
    context.read<ProfileProvider>().clearSelection();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final profile = context.watch<ProfileProvider>();
    final menu = context.watch<MenuProvider>();
    final categories = menu.categories;

    // Generate PromptPay QR data
    String? qrData;
    if (profile.promptPayId.isNotEmpty && cart.finalTotal > 0) {
      qrData = PromptPayQR.generate(
        promptPayId: profile.promptPayId,
        amount: cart.finalTotal,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary / สรุปออเดอร์'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Guest Name (not saved, one-time use)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Guest Name / ชื่อผู้สั่ง',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Name for this order only / ชื่อสำหรับออเดอร์นี้เท่านั้น',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: _guestNameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Enter guest name / ใส่ชื่อ',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Pickup or Delivery + Time
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pickup or Delivery? / รับเองหรือจัดส่ง?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _orderType = 'pickup'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _orderType == 'pickup'
                                ? Colors.deepOrange
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.deepOrange),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store,
                                  color: _orderType == 'pickup'
                                      ? Colors.white
                                      : Colors.deepOrange,
                                  size: 20),
                              const SizedBox(width: 6),
                              Text('Pickup\nรับเอง',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: _orderType == 'pickup'
                                          ? Colors.white
                                          : Colors.deepOrange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _orderType = 'delivery'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _orderType == 'delivery'
                                ? Colors.deepOrange
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.deepOrange),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delivery_dining,
                                  color: _orderType == 'delivery'
                                      ? Colors.white
                                      : Colors.deepOrange,
                                  size: 20),
                              const SizedBox(width: 6),
                              Text('Delivery\nจัดส่ง',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: _orderType == 'delivery'
                                          ? Colors.white
                                          : Colors.deepOrange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('What time? / เวลาไหน?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.availableHours.map((hour) {
                    final isSelected = _selectedHour == hour;
                    final period = hour < 12 ? 'AM' : 'PM';
                    final display12 = hour > 12 ? hour - 12 : hour;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedHour = hour),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepOrange : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.deepOrange
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$display12 $period',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              '$hour:00',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Items
          const Text('Items / รายการอาหาร',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(cart.items.length, (index) {
            final item = cart.items[index];
            final cat = menu.categoryFor(item.productType);
            final hasToppings = cat?.hasToppings ?? false;
            final itemIcon = cat != null ? iconFromString(cat.icon) : Icons.restaurant;
            final itemColor = cat != null ? colorFromString(cat.color) : Colors.deepOrange;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(itemIcon, color: itemColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.productNameThai} / ${item.productName}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    if (item.toppings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4),
                        child: Text(
                          item.toppings
                              .map((t) =>
                                  '${t.nameThai} / ${t.name} +${t.price.toInt()}')
                              .join(', '),
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text(
                        'x${item.quantity} = ${item.itemTotal.toInt()} THB',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasToppings)
                          TextButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy / คัดลอก'),
                            onPressed: () => cart.duplicateItem(index),
                          ),
                        if (!hasToppings) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                cart.updateQuantity(index, item.quantity - 1),
                          ),
                          Text('${item.quantity}',
                              style: const TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                cart.updateQuantity(index, item.quantity + 1),
                          ),
                        ],
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.red),
                          onPressed: () => cart.removeItem(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const Divider(height: 32),

          // Discount - dynamic per category
          const Text('Discount / ส่วนลด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final cat in categories) ...[
            if (cart.countForCategory(cat.key) > 0 && (cart.categoryDiscounts[cat.key] ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    '${cat.labelThai} ${cart.countForCategory(cat.key)} × ${(cart.categoryDiscounts[cat.key] ?? 0).toInt()} = -${cart.discountForCategory(cat.key).toInt()} THB\n'
                    '${cat.label}: ${cart.countForCategory(cat.key)} × ${(cart.categoryDiscounts[cat.key] ?? 0).toInt()} THB'),
              ),
          ],

          const Divider(height: 32),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text('Guest Pays / แขกจ่าย')),
                    Text('${cart.subtotal.toInt()} THB'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text('Discount / ลด')),
                    Text('-${cart.totalDiscount.toInt()} THB',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text('You Pay / คุณจ่าย',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Text('${cart.finalTotal.toInt()} THB',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Step 1: Confirm Order button
          if (!_orderConfirmed) ...[
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: cart.isEmpty ? null : _sendConfirmation,
                icon: const Icon(Icons.check_circle, size: 24),
                label: const Text('Confirm Order / ยืนยันออเดอร์',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sends order details via LINE for confirmation before payment\nส่งรายละเอียดทาง LINE เพื่อยืนยันก่อนชำระเงิน',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],

          // Send button + Warning banner (visible after confirm tapped)
          if (_orderConfirmed) ...[
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: cart.isEmpty ? null : _doShareConfirmation,
                icon: const Icon(Icons.send, size: 24),
                label: const Text('Send to shop on LINE / ส่งไปร้านทาง LINE',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06C755),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'IMPORTANT',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wait for reply on LINE before you take payment!\n\nรอตอบกลับทาง LINE ก่อนเก็บเงิน!',
                    style: TextStyle(fontSize: 16, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Step 2: Payment (only visible after confirmation)
          if (_orderConfirmed) ...[
          // Payment QR
          const Text('Payment / การชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (profile.promptPayId.isNotEmpty && cart.finalTotal > 0) ...[
            // Option 1: Pay from this phone (copy details to banking app)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Pay from this phone / จ่ายจากโทรศัพท์นี้',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Open your banking app and transfer to:\nเปิดแอปธนาคารแล้วโอนเงินไปที่:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('PromptPay: ', style: TextStyle(fontSize: 15)),
                      Text(
                        profile.promptPayId,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: profile.promptPayId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PromptPay ID copied! / คัดลอกแล้ว!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Amount / จำนวน: ',
                          style: TextStyle(fontSize: 15)),
                      Text(
                        '${cart.finalTotal.toInt()} THB',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: cart.finalTotal.toInt().toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Amount copied! / คัดลอกจำนวนแล้ว!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Option 2: QR for scanning from another phone
            if (qrData != null)
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Or scan from another phone / หรือสแกนจากโทรศัพท์อื่น',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: qrData!,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                  ],
                ),
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PromptPay ID not set. Go to Admin settings to configure.\n'
                'ยังไม่ได้ตั้งค่า PromptPay ID กรุณาไปตั้งค่าในหน้า Admin',
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // Payment Screenshot
          const Text('Payment Confirmation / ยืนยันการชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_paymentScreenshot != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_paymentScreenshot!, height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _paymentScreenshot = null),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Remove / ลบ', style: TextStyle(color: Colors.red)),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickScreenshot,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery / แกลเลอรี'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takeScreenshot,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera / กล้อง'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Send to LINE
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: cart.isEmpty ? null : _sendToLine,
              icon: const Icon(Icons.send, size: 24),
              label: const Text('Send to shop on LINE / ส่งไปร้านทาง LINE',
                  style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06C755), // LINE green
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),
          ], // end if (_orderConfirmed)
        ],
      ),
    );
  }
}
