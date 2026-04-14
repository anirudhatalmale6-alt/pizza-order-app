/// Generates PromptPay EMVCo QR code data string with amount
/// Based on Bank of Thailand PromptPay QR specification (EMVCo standard)
class PromptPayQR {
  static String generate({required String promptPayId, required double amount}) {
    // Clean the ID
    final id = promptPayId.replaceAll(RegExp(r'[^0-9]'), '');

    // Determine account type
    String formattedId;
    if (id.length >= 13) {
      // National ID (13 digits)
      formattedId = id.substring(0, 13);
    } else if (id.length >= 10) {
      // Phone number - add country code 66, remove leading 0
      final phone = id.startsWith('0') ? id.substring(1) : id;
      formattedId = '0066${phone.padLeft(9, '0')}';
    } else {
      formattedId = id;
    }

    // Build EMVCo TLV
    final sb = StringBuffer();

    // Payload Format Indicator
    sb.write(_tlv('00', '01'));

    // Point of Initiation Method (12 = dynamic)
    sb.write(_tlv('01', '12'));

    // Merchant Account Information (tag 29 for PromptPay)
    final aid = _tlv('00', 'A000000677010111'); // PromptPay AID
    final accountId = _tlv('01', formattedId);
    sb.write(_tlv('29', '$aid$accountId'));

    // Transaction Currency (764 = THB)
    sb.write(_tlv('53', '764'));

    // Transaction Amount
    if (amount > 0) {
      sb.write(_tlv('54', amount.toStringAsFixed(2)));
    }

    // Country Code
    sb.write(_tlv('58', 'TH'));

    // CRC placeholder (tag 63, length 04)
    final dataForCrc = '${sb}6304';
    final crc = _crc16(dataForCrc);
    sb.write('6304$crc');

    return sb.toString();
  }

  static String _tlv(String tag, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  static String _crc16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
