import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _orderType = 'pickup';
  int? _selectedHour;
  final _guestNameCtrl = TextEditingController();
  bool _confirmationSent = false;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

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
            '- ${item.productNameThai} / ${item.productName}$toppingsStr x${item.quantity} → ${_fmt(item.basePrice)} +${_fmt(item.toppingsTotal)} = ${_fmt(item.itemTotal)} THB');
      } else {
        sb.writeln(
            '- ${item.productNameThai} / ${item.productName} x${item.quantity} → ${_fmt(item.itemTotal)} THB');
      }
    }

    sb.writeln();
    final subtotal = cart.subtotal;
    final discountAmt = _calcTotalDiscount();
    if (discountAmt > 0) {
      final finalTotal = _calcFinalTotal();
      sb.writeln('Subtotal / ยอดรวม: ${_fmt(subtotal)} THB');
      sb.writeln('Discount / ส่วนลด: -${_fmt(discountAmt)} THB');
      sb.writeln('Final Total / ยอดสุทธิ: ${_fmt(finalTotal)} THB');
    } else {
      sb.writeln('Total / ยอดรวม: ${_fmt(subtotal)} THB');
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
        sb.writeln('- ${item.productName}$toppingsStr x${item.quantity} = ${_fmt(item.itemTotal)} THB');
      } else {
        sb.writeln('- ${item.productName} x${item.quantity} = ${_fmt(item.itemTotal)} THB');
      }
    }
    sb.writeln();
    final subtotal = cart.subtotal;
    final discountAmt2 = _calcTotalDiscount();
    if (discountAmt2 > 0) {
      final finalTotal = _calcFinalTotal();
      sb.writeln('Subtotal / ยอดรวม: ${_fmt(subtotal)} THB');
      sb.writeln('Discount / ส่วนลด: -${_fmt(discountAmt2)} THB');
      sb.writeln('Total / รวม: ${_fmt(finalTotal)} THB');
    } else {
      sb.writeln('Total / รวม: ${_fmt(subtotal)} THB');
    }
    sb.writeln('================================');
    sb.writeln('Please confirm this order is OK');
    sb.writeln('กรุณายืนยันว่าออเดอร์ถูกต้อง');

    return sb.toString();
  }

  Future<void> _sendConfirmation() async {
    final text = _buildConfirmText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    setState(() => _confirmationSent = true);

    final menu = context.read<MenuProvider>();
    final profile = context.read<ProfileProvider>();
    final lineLink = menu.lineLink.isNotEmpty ? menu.lineLink : profile.lineDeepLink;

    if (lineLink.isNotEmpty) {
      await launchUrl(Uri.parse(lineLink), mode: LaunchMode.externalApplication);
    } else {
      try {
        await Share.share(text);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order copied to clipboard! Paste in LINE.\nคัดลอกแล้ว! วางใน LINE'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
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
                        'x${item.quantity} = ${_fmt(item.itemTotal)} THB',
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
                      const Flexible(child: Text('Customer to Pay / ลูกค้าจ่าย')),
                      Text('${_fmt(subtotal)} THB'),
                    ],
                  ),
                  if (discountAmt > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text('You Earned / คุณได้รับ')),
                        Text('-${_fmt(discountAmt)} THB',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('You Pay / คุณจ่าย',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Text('${_fmt(finalTotal)} THB',
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

          // Send order for confirmation
          SizedBox(
            height: 64,
            child: ElevatedButton.icon(
              onPressed: (cart.isEmpty || _confirmationSent) ? null : _sendConfirmation,
              icon: Icon(_confirmationSent ? Icons.check : Icons.send, size: 22),
              label: Text(_confirmationSent
                  ? 'Sent! / ส่งแล้ว!'
                  : 'Send to shop for confirmation\nส่งไปร้านเพื่อยืนยัน',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _confirmationSent ? Colors.grey : const Color(0xFF06C755),
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
                    'Amount / จำนวน: ${_fmt(_calcFinalTotal())} THB',
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

          const SizedBox(height: 16),

          // Send payment slip instructions
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
                const Text('Send Payment Slip / ส่งสลิปการชำระ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Attach the payment slip from Gallery or take a photo with Camera and send to ${profile.appName} on LINE.\n\n'
                  'แนบสลิปจากแกลเลอรี หรือถ่ายรูปด้วยกล้อง แล้วส่งไปที่ ${profile.appName} บน LINE',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                Builder(builder: (context) {
                  final effectiveLineLink = menu.lineLink.isNotEmpty
                      ? menu.lineLink
                      : profile.lineDeepLink;
                  if (effectiveLineLink.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          context.read<CartProvider>().clear();
                          context.read<ProfileProvider>().clearSelection();
                          await launchUrl(Uri.parse(effectiveLineLink),
                              mode: LaunchMode.externalApplication);
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble, size: 20),
                        label: Text('Open ${profile.appName} on LINE',
                            style: const TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06C755),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
