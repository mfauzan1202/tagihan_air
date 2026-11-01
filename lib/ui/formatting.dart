import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tagihan_air/models/bill.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final _thousands = NumberFormat.decimalPattern('id_ID');
final _shortDate = DateFormat('d MMM yyyy', 'id_ID');
final _longDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
final _period = DateFormat('MMMM yyyy', 'id_ID');

String formatRupiah(int amount) => _rupiah.format(amount);

String formatDate(DateTime date) => _shortDate.format(date);

String formatLongDate(DateTime date) => _longDate.format(date);

String formatPeriod(int year, int month) =>
    _period.format(DateTime(year, month));

String dueLabel(Bill bill, DateTime today) {
  if (bill.isPaid) return 'Lunas';
  final days = bill.daysUntilDue(today);
  return switch (days) {
    < 0 => 'Terlambat ${-days} hari',
    0 => 'Hari ini',
    1 => 'Besok',
    _ => '$days hari lagi',
  };
}

int? parseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : int.parse(digits);
}

class ThousandsSeparatorFormatter extends TextInputFormatter {
  const ThousandsSeparatorFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    if (digits.length > maxDigits) return oldValue;

    final text = _thousands.format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
