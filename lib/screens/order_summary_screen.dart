import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category_config.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../models/cart_item.dart';
import '../widgets/topping_dialog.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  Uint8List? _screenshotBytes;
  bool _hasScreenshot = false;
  String _orderType = 'pickup';
  int? _selectedHour;
  final _guestNameCtrl = TextEditingController();

  double _calcTotalDiscount() {
    final cart = context.read<CartProvider>();
    final profile = context.read<ProfileProvider>();
    double discount = cart.totalDiscount;
    final afterCat = cart.subtotal - discount;
    if (profile.discountPercent > 0 && afterCat > 0) {
      discount += afterCat * profile.discountPercent / 100;
    }
    return discount;
  }

  double _calcFinalTotal() {
    final cart = context.read<CartProvider>();
    return (cart.subtotal - _calcTotalDiscount()).clamp(0, double.infinity);
  }

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _screenshotBytes = bytes;
        _hasScreenshot = true;
      });
    }
  }

  Future<void> _takeScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _screenshotBytes = bytes;
        _hasScreenshot = true;
      });
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
    if (profile.offersDelivery) {
      final typeText = _orderType == 'pickup'
          ? 'Pickup / รับเอง'
          : 'Delivery / จัดส่ง';
      sb.writeln('Type / ประเภท: $typeText');
    }
    if (_selectedHour != null) {
      final period = _selectedHour! < 12 ? 'AM' : 'PM';
      final display12 = _selectedHour! > 12 ? _selectedHour! - 12 : _selectedHour!;
      sb.writeln('Time / เวลา: ${display12}:00 $period ($_selectedHour:00)');
    }
    sb.writeln();
    sb.writeln('Your Order / รายการ:');

    for (final item in cart.items) {
      if (item.toppings.isNotEmpty) {
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
    final subtotal = cart.subtotal;
    final discountAmt = _calcTotalDiscount();
    if (discountAmt > 0) {
      final finalTotal = _calcFinalTotal();
      sb.writeln('Subtotal / ยอดรวม: ${subtotal.toInt()} THB');
      sb.writeln('Discount / ส่วนลด: -${discountAmt.toInt()} THB');
      sb.writeln('Final Total / ยอดสุทธิ: ${finalTotal.toInt()} THB');
    } else {
      sb.writeln('Total / ยอดรวม: ${subtotal.toInt()} THB');
    }
    sb.writeln();
    sb.writeln('ชำระโดย / Payment via PromptPay');
    sb.writeln('เวลา / Time: $now');

    return sb.toString();
  }

  String _buildConfirmText() {
    final cart = context.read<CartProvider>();
    final profile = context.read<ProfileProvider>();
    final menu = context.read<MenuProvider>();

    final sb = StringBuffer();
    sb.writeln('NEW ORDER / ออเดอร์ใหม่');
    sb.writeln('================================');
    if (_guestNameCtrl.text.trim().isNotEmpty) {
      sb.writeln('Guest / ชื่อผู้สั่ง: ${_guestNameCtrl.text.trim()}');
    }
    sb.writeln('Staff / พนักงาน: ${profile.customerName}');
    if (profile.businessName.isNotEmpty) {
      sb.writeln('Business / ธุรกิจ: ${profile.businessName}');
    }
    sb.writeln();

    if (profile.offersDelivery) {
      final typeText = _orderType == 'pickup'
          ? 'Pickup / รับเอง'
          : 'Delivery / จัดส่ง';
      sb.writeln('Type / ประเภท: $typeText');
    }
    if (_selectedHour != null) {
      final period = _selectedHour! < 12 ? 'AM' : 'PM';
      final display12 = _selectedHour! > 12 ? _selectedHour! - 12 : _selectedHour!;
      sb.writeln('Time / เวลา: ${display12}:00 $period ($_selectedHour:00)');
    }
    sb.writeln();

    sb.writeln('Your Order / รายการ:');
    for (final item in cart.items) {
      if (item.toppings.isNotEmpty) {
        final toppingsStr = ' + ${item.toppings.map((t) => t.name).join(', ')}';
        sb.writeln('- ${item.productName}$toppingsStr x${item.quantity} = ${item.itemTotal.toInt()} THB');
      } else {
        sb.writeln('- ${item.productName} x${item.quantity} = ${item.itemTotal.toInt()} THB');
      }
    }
    sb.writeln();
    final subtotal = cart.subtotal;
    final discountAmt2 = _calcTotalDiscount();
    if (discountAmt2 > 0) {
      final finalTotal = _calcFinalTotal();
      sb.writeln('Subtotal / ยอดรวม: ${subtotal.toInt()} THB');
      sb.writeln('Discount / ส่วนลด: -${discountAmt2.toInt()} THB');
      sb.writeln('Total / รวม: ${finalTotal.toInt()} THB');
    } else {
      sb.writeln('Total / รวม: ${subtotal.toInt()} THB');
    }
    sb.writeln('================================');
    sb.writeln('Please confirm this order is OK');
    sb.writeln('กรุณายืนยันว่าออเดอร์ถูกต้อง');

    return sb.toString();
  }

  void _copyConfirmation() {
    final text = _buildConfirmText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order copied! Paste in LINE.\nคัดลอกแล้ว! วางใน LINE'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _copyAndSend() {
    final text = _buildOrderText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order copied! Paste in LINE.\nคัดลอกแล้ว! วางใน LINE'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _completeOrder() {
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Order Summary'),
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

          // Pickup/Delivery + Time
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
                if (profile.offersDelivery) ...[
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
                ],
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
          const Text('Your Order / รายการอาหาร',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(cart.items.length, (index) {
            final item = cart.items[index];
            final cat = menu.categoryFor(item.productType);
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
                        if (menu.toppingsForItem(item.productName, item.productType).isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit / แก้ไข'),
                            onPressed: () async {
                              final toppings = menu.toppingsForItem(item.productName, item.productType);
                              final selected = await showDialog<List<SelectedTopping>>(
                                context: context,
                                builder: (_) => ToppingDialog(
                                  availableToppings: toppings,
                                  categoryLabel: item.productName,
                                  initialSelection: item.toppings,
                                  isEditing: true,
                                ),
                              );
                              if (selected != null) {
                                cart.replaceItem(index, item.copyWith(toppings: selected));
                              }
                            },
                          ),
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

          const Divider(height: 32),

          // Total
          Builder(builder: (context) {
            final subtotal = cart.subtotal;
            final discountAmt = _calcTotalDiscount();
            final finalTotal = _calcFinalTotal();
            return Container(
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
                      const Flexible(child: Text('Subtotal / ยอดรวม')),
                      Text('${subtotal.toInt()} THB'),
                    ],
                  ),
                  if (discountAmt > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text('Discount / ส่วนลด')),
                        Text('-${discountAmt.toInt()} THB',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('Total / ยอดสุทธิ',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Text('${finalTotal.toInt()} THB',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange)),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Step 1: Confirm order via LINE
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
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Confirm Order / ยืนยันออเดอร์',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Copy the order, open LINE, paste and send to the shop.\nWait for reply before taking payment.\n\n'
                  'คัดลอกออเดอร์ เปิด LINE วางแล้วส่งไปร้าน\nรอตอบกลับก่อนเก็บเงิน',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: cart.isEmpty ? null : _copyConfirmation,
                    icon: const Icon(Icons.copy, size: 20),
                    label: const Text('Copy Order / คัดลอกออเดอร์',
                        style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment
          const Text('Payment / การชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (profile.promptPayId.isNotEmpty && _calcFinalTotal() > 0) ...[
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
                    'Transfer to / โอนเงินไปที่',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Open banking app and transfer to:\nเปิดแอปธนาคารแล้วโอนเงินไปที่:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PromptPay: ${profile.promptPayId}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amount / จำนวน: ${_calcFinalTotal().toInt()} THB',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Acct'),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: profile.promptPayId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account number copied! / คัดลอกแล้ว!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Amt'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: _calcFinalTotal().toInt().toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Amount copied! / คัดลอกจำนวนแล้ว!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
          const SizedBox(height: 4),
          const Text(
            'Load payment slip from gallery or take a photo with camera.\n'
            'โหลดสลิปจากแกลเลอรีหรือถ่ายรูปด้วยกล้อง',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_hasScreenshot && _screenshotBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_screenshotBytes!, height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _screenshotBytes = null;
                _hasScreenshot = false;
              }),
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

          const SizedBox(height: 16),

          // Step 2: Send payment receipt
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Send Payment / ส่งการชำระเงิน',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Copy the payment receipt, open LINE, paste and send.\n'
                  'Also send the payment slip photo from your gallery.\n\n'
                  'คัดลอกใบเสร็จ เปิด LINE วางแล้วส่ง\n'
                  'ส่งรูปสลิปจากแกลเลอรีด้วย',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: cart.isEmpty ? null : _copyAndSend,
                    icon: const Icon(Icons.copy, size: 20),
                    label: const Text('Copy Payment Receipt / คัดลอกใบเสร็จ',
                        style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06C755),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Complete order
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _completeOrder,
              icon: const Icon(Icons.check_circle, size: 22),
              label: const Text('Order Complete / เสร็จสิ้น',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Return to menu
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.menu_book),
              label: const Text('Return to Menu / กลับไปเมนู',
                  style: TextStyle(fontSize: 14)),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
