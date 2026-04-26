import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/menu_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/platform_image.dart';

class RenewalScreen extends StatefulWidget {
  final bool canContinue;

  const RenewalScreen({super.key, required this.canContinue});

  @override
  State<RenewalScreen> createState() => _RenewalScreenState();
}

class _RenewalScreenState extends State<RenewalScreen> {
  XFile? _paymentScreenshot;
  bool _syncing = false;
  bool _receiptSent = false;

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _paymentScreenshot = image);
  }

  Future<void> _takeScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) setState(() => _paymentScreenshot = image);
  }

  String _buildRenewalText() {
    final profile = context.read<ProfileProvider>();
    final menu = context.read<MenuProvider>();
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    final expiryStr = menu.expiresDate != null
        ? DateFormat('dd MMM yyyy').format(menu.expiresDate!)
        : 'Unknown';

    final sb = StringBuffer();
    sb.writeln('RENEWAL PAYMENT / ชำระค่าต่ออายุ');
    sb.writeln('================================');
    sb.writeln('Business / ธุรกิจ: ${profile.appName}');
    sb.writeln('Expiry Date / วันหมดอายุ: $expiryStr');
    if (menu.renewalPrice > 0) {
      sb.writeln('Amount / จำนวน: ${menu.renewalPrice.toInt()} THB');
    }
    sb.writeln();
    sb.writeln('ชำระโดย / Payment via PromptPay');
    sb.writeln('PromptPay: ${profile.promptPayId}');
    sb.writeln('เวลา / Time: $now');
    return sb.toString();
  }

  Future<void> _sendReceipt() async {
    final text = _buildRenewalText();
    await Clipboard.setData(ClipboardData(text: text));

    // Send text details first
    try {
      await Share.share(text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt copied to clipboard! Paste in LINE.\nคัดลอกใบเสร็จแล้ว! วางใน LINE'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    // Tell user to send slip from gallery
    if (_paymentScreenshot != null && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Details Sent!\nส่งรายละเอียดแล้ว!'),
          content: const Text(
            'Renewal details sent to LINE!\n\n'
            'Now open LINE and send the payment slip photo from your gallery.\n\n'
            'ส่งรายละเอียดไปทาง LINE แล้ว!\n\n'
            'เปิด LINE แล้วส่งรูปสลิปจากแกลเลอรีของคุณ',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06C755),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done / เสร็จ'),
            ),
          ],
        ),
      );
    }

    if (mounted) {
      setState(() => _receiptSent = true);
      final menu = context.read<MenuProvider>();
      if (menu.isExpired) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 8),
                const Expanded(child: Text('Thank You!\nขอบคุณ!')),
              ],
            ),
            content: const Text(
              'Your payment has been sent. The app will be restored within 12 hours.\n\n'
              'ส่งการชำระเงินแล้ว แอปจะกลับมาใช้งานได้ภายใน 12 ชั่วโมง',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _syncAndCheck() async {
    setState(() => _syncing = true);
    final menu = context.read<MenuProvider>();
    await menu.syncFromSheet();
    if (mounted) {
      setState(() => _syncing = false);
      if (!menu.isExpired && !menu.isInRenewalWindow) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription active! Returning to app.\nสมัครสมาชิกเรียบร้อย! กลับไปแอป'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.canContinue && mounted) {
          Navigator.of(context).pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(menu.isExpired
                ? 'Still expired. Please contact for renewal.\nยังหมดอายุอยู่ กรุณาติดต่อต่ออายุ'
                : 'Synced. Expiry date updated.\nซิงค์แล้ว อัปเดตวันหมดอายุ'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final profile = context.watch<ProfileProvider>();
    final isExpired = menu.isExpired;
    final expiryStr = menu.expiresDate != null
        ? DateFormat('dd MMM yyyy').format(menu.expiresDate!)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isExpired
            ? 'Subscription Expired / หมดอายุ'
            : 'Renewal / ต่ออายุ'),
        backgroundColor: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: widget.canContinue,
      ),
      bottomNavigationBar: (widget.canContinue && _receiptSent)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue to App / เข้าใช้งานต่อ',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpired ? Colors.red.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpired ? Colors.red.shade300 : Colors.orange.shade300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isExpired ? Icons.block : Icons.warning_amber_rounded,
                  size: 64,
                  color: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                ),
                const SizedBox(height: 12),
                Text(
                  isExpired
                      ? 'Subscription Expired\nหมดอายุการใช้งาน'
                      : 'Subscription Expiring Soon\nใกล้หมดอายุ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                if (expiryStr.isNotEmpty)
                  Text(
                    isExpired
                        ? 'Expired on / หมดอายุเมื่อ: $expiryStr'
                        : 'Expires on / หมดอายุ: $expiryStr (${menu.daysUntilExpiry} days)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isExpired ? Colors.red.shade600 : Colors.orange.shade700,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  isExpired
                      ? 'Please renew your subscription to continue using the app.\nกรุณาต่ออายุเพื่อใช้งานแอปต่อ'
                      : 'Please renew soon to avoid interruption.\nกรุณาต่ออายุก่อนหมด',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // PromptPay payment section
          if (profile.promptPayId.isNotEmpty) ...[
            const Text('Payment / การชำระเงิน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
                  if (menu.renewalPrice > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Amount / จำนวน: ${menu.renewalPrice.toInt()} THB',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Acct'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: profile.promptPayId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account copied! / คัดลอกแล้ว!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      if (menu.renewalPrice > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy Amt'),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: menu.renewalPrice.toInt().toString()));
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
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Payment screenshot
          const Text('Payment Screenshot / สลิปการชำระ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_paymentScreenshot != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: platformFileImage(_paymentScreenshot!.path,
                  height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _paymentScreenshot = null),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Remove / ลบ',
                  style: TextStyle(color: Colors.red)),
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

          // Send receipt button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _sendReceipt,
              icon: const Icon(Icons.send, size: 22),
              label: const Text(
                'Send Renewal Receipt\nส่งใบเสร็จต่ออายุ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06C755),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
