import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/ui/formatting.dart';

import '../support/test_bills.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('formats Rupiah with dot separators and no decimals', () {
    expect(formatRupiah(98200), 'Rp 98.200');
    expect(formatRupiah(1250000), 'Rp 1.250.000');
  });

  test('formats billing period in Indonesian', () {
    expect(formatPeriod(2026, 10), 'Oktober 2026');
    expect(formatDate(DateTime(2026, 8, 20)), '20 Agu 2026');
  });

  group('dueLabel', () {
    final today = DateTime(2026, 11, 1, 9);

    String labelFor(DateTime due, {BillStatus status = BillStatus.unpaid}) =>
        dueLabel(testBill(id: 1, dueDate: due, status: status), today);

    test('describes upcoming, current and overdue bills', () {
      expect(labelFor(DateTime(2026, 11, 4)), '3 hari lagi');
      expect(labelFor(DateTime(2026, 11, 2)), 'Besok');
      expect(labelFor(DateTime(2026, 11, 1)), 'Hari ini');
      expect(labelFor(DateTime(2026, 10, 30)), 'Terlambat 2 hari');
    });

    test('says Lunas for paid bills even when past due', () {
      expect(
        labelFor(DateTime(2026, 10, 20), status: BillStatus.paid),
        'Lunas',
      );
    });
  });

  group('ThousandsSeparatorFormatter', () {
    const formatter = ThousandsSeparatorFormatter(maxDigits: 9);

    String type(String text, {String previous = ''}) => formatter
        .formatEditUpdate(
          TextEditingValue(text: previous),
          TextEditingValue(text: text),
        )
        .text;

    test('groups digits as the user types', () {
      expect(type('1250000'), '1.250.000');
      expect(type('1.250.0001'), '12.500.001');
    });

    test('drops non-digits and leading zeros', () {
      expect(type('Rp 0098a200'), '98.200');
      expect(type('abc'), '');
    });

    test('keeps the previous value past the digit limit', () {
      expect(type('1234567890', previous: '123.456.789'), '123.456.789');
    });

    test('round-trips through parseRupiah', () {
      expect(parseRupiah(type('1250000')), 1250000);
      expect(parseRupiah(''), isNull);
    });
  });
}
