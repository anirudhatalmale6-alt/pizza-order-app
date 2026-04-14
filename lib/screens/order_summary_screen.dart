import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/promptpay_qr.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  File? _paymentScreenshot;

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

  String _buildOrderText() {
    final cart = context.read<CartProvider>();
    final profile = context.read<ProfileProvider>();
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    final sb = StringBuffer();
    sb.writeln('คำสั่งซื้อ / Order from: ${profile.customerName}');
    sb.writeln('ชื่อธุรกิจ / Business: ${profile.businessName}');
    sb.writeln();
    sb.writeln('รายการอาหาร / Items:');

    for (final item in cart.items) {
      if (item.productType == 'pizza') {
        final toppingsStr = item.toppings.isNotEmpty
            ? ' (${item.toppings.map((t) => '${t.nameThai} +${t.price.toInt()} / ${t.name} +${t.price.toInt()}').join(', ')})'
            : '';
        sb.writeln(
            '- ${item.productNameThai} / ${item.productName}$toppingsStr x${item.quantity} → ${item.basePrice.toInt()} +${item.toppingsTotal.toInt()} = ${item.itemTotal.toInt()} THB');
      } else {
        sb.writeln(
            '- ${item.productNameThai} / ${item.productName} x${item.quantity} → ${item.itemTotal.toInt()} THB');
      }
    }

    sb.writeln();
    sb.writeln('ส่วนลด / Discount:');
    sb.writeln(
        '- พิซซ่า ${cart.pizzaCount} ชิ้น ×${cart.pizzaDiscount.toInt()} / ${cart.pizzaCount} pizzas ×${cart.pizzaDiscount.toInt()} = ${cart.totalPizzaDiscount.toInt()} THB');
    sb.writeln(
        '- เครื่องดื่ม ${cart.drinkCount} ขวด ×${cart.drinkDiscount.toInt()} / ${cart.drinkCount} drinks ×${cart.drinkDiscount.toInt()} = ${cart.totalDrinkDiscount.toInt()} THB');
    sb.writeln();
    sb.writeln('ยอดรวมสุดท้าย / Final total: ${cart.finalTotal.toInt()} THB');
    sb.writeln();
    sb.writeln('ชำระโดย / Payment via PromptPay QR');
    sb.writeln('เวลา / Time: $now');

    return sb.toString();
  }

  Future<void> _sendToLine() async {
    final orderText = _buildOrderText();

    // Try LINE's share URL scheme first (opens LINE directly with text)
    final lineShareUrl = Uri.parse(
        'https://line.me/R/share?text=${Uri.encodeComponent(orderText)}');

    final hasLine = await canLaunchUrl(lineShareUrl);

    if (hasLine) {
      // Opens LINE directly with the order text
      await launchUrl(lineShareUrl, mode: LaunchMode.externalApplication);

      // If there's a payment screenshot, share it separately after
      if (_paymentScreenshot != null && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        await Share.shareXFiles(
          [XFile(_paymentScreenshot!.path)],
          text: 'Payment confirmation / หลักฐานการชำระเงิน',
        );
      }
    } else {
      // Fallback: use generic share (user picks LINE from share sheet)
      if (_paymentScreenshot != null) {
        await Share.shareXFiles(
          [XFile(_paymentScreenshot!.path)],
          text: orderText,
        );
      } else {
        await Share.share(orderText);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Order shared! Pick a LINE contact to send.\n'
              'เลือกผู้ติดต่อ LINE เพื่อส่งออเดอร์'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final profile = context.watch<ProfileProvider>();

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
          // Items
          const Text('Items / รายการอาหาร',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(cart.items.length, (index) {
            final item = cart.items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.productType == 'pizza'
                              ? Icons.local_pizza
                              : Icons.local_drink,
                          color: item.productType == 'pizza'
                              ? Colors.deepOrange
                              : Colors.blue,
                        ),
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
                        if (item.productType == 'pizza')
                          TextButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy / คัดลอก'),
                            onPressed: () => cart.duplicateItem(index),
                          ),
                        if (item.productType == 'drink') ...[
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

          // Discount
          const Text('Discount / ส่วนลด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'พิซซ่า ${cart.pizzaCount} ชิ้น × ${cart.pizzaDiscount.toInt()} = -${cart.totalPizzaDiscount.toInt()} THB\n'
              'Pizzas: ${cart.pizzaCount} × ${cart.pizzaDiscount.toInt()} THB'),
          const SizedBox(height: 4),
          Text(
              'เครื่องดื่ม ${cart.drinkCount} ขวด × ${cart.drinkDiscount.toInt()} = -${cart.totalDrinkDiscount.toInt()} THB\n'
              'Drinks: ${cart.drinkCount} × ${cart.drinkDiscount.toInt()} THB'),

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
                    const Text('Subtotal / ยอดรวม'),
                    Text('${cart.subtotal.toInt()} THB'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount / ส่วนลด'),
                    Text('-${cart.totalDiscount.toInt()} THB',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Final Total / ยอดรวมสุดท้าย',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
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

          // Payment QR
          const Text('Payment / การชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (qrData != null)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 250,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan to pay ${cart.finalTotal.toInt()} THB\nสแกนเพื่อชำระ ${cart.finalTotal.toInt()} บาท',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          else
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
              label: const Text('Send to LINE / ส่งไปยัง LINE',
                  style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06C755), // LINE green
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
