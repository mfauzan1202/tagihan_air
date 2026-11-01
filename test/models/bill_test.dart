import 'package:flutter_test/flutter_test.dart';
import 'package:tagihan_air/models/bill.dart';

Bill _bill({required DateTime dueDate, BillStatus status = BillStatus.unpaid}) {
  return Bill(
    id: 1,
    customerNumber: '0113002451',
    customerName: 'Siti Rahmawati',
    periodYear: 2026,
    periodMonth: 10,
    usageM3: 16,
    amount: 98200,
    dueDate: dueDate,
    status: status,
    paidAt: status == BillStatus.paid ? DateTime(2026, 11, 18) : null,
  );
}

void main() {
  group('daysUntilDue', () {
    test('is zero on the due date regardless of time of day', () {
      final bill = _bill(dueDate: DateTime(2026, 11, 20));

      expect(bill.daysUntilDue(DateTime(2026, 11, 20, 0, 1)), 0);
      expect(bill.daysUntilDue(DateTime(2026, 11, 20, 23, 59)), 0);
    });

    test('counts whole days across a month boundary', () {
      final bill = _bill(dueDate: DateTime(2026, 12, 2));

      expect(bill.daysUntilDue(DateTime(2026, 11, 29, 21)), 3);
    });

    test('is negative after the due date', () {
      final bill = _bill(dueDate: DateTime(2026, 11, 20));

      expect(bill.daysUntilDue(DateTime(2026, 11, 22, 8)), -2);
    });
  });

  group('isOverdue', () {
    test('is true for an unpaid bill past its due date', () {
      final bill = _bill(dueDate: DateTime(2026, 11, 20));

      expect(bill.isOverdue(DateTime(2026, 11, 21)), isTrue);
      expect(bill.isOverdue(DateTime(2026, 11, 20)), isFalse);
    });

    test('is false once the bill is paid', () {
      final bill = _bill(
        dueDate: DateTime(2026, 11, 20),
        status: BillStatus.paid,
      );

      expect(bill.isOverdue(DateTime(2026, 12, 1)), isFalse);
    });
  });

  test('toDraft keeps the editable fields', () {
    final draft = _bill(dueDate: DateTime(2026, 11, 20)).toDraft();

    expect(draft.customerNumber, '0113002451');
    expect(draft.periodMonth, 10);
    expect(draft.amount, 98200);
    expect(draft.dueDate, DateTime(2026, 11, 20));
  });
}
