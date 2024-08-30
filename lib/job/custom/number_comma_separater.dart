import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String newText = newValue.text;

    // Remove all non-digit characters
    final String digits = newText.replaceAll(RegExp(r'\D'), '');

    // Format with commas
    final String formatted = _formatWithCommas(digits);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithCommas(String digits) {
    if (digits.isEmpty) return '';

    final int length = digits.length;
    final int commaCount = (length - 1) ~/ 3;
    final int firstGroupLength = length % 3 == 0 ? 3 : length % 3;

    final StringBuffer buffer = StringBuffer();

    buffer.write(digits.substring(0, firstGroupLength));

    for (int i = firstGroupLength; i < length; i += 3) {
      if (i + 3 <= length) {
        buffer.write(',${digits.substring(i, i + 3)}');
      } else {
        buffer.write(',${digits.substring(i)}');
      }
    }

    return buffer.toString();
  }
}
