import 'package:flutter_test/flutter_test.dart';
import 'package:tagihan_air/data/sample_bills.dart';

import '../support/fake_bill_repository.dart';

void main() {
  final today = DateTime(2026, 11, 1, 8);

  test('seeds ten bills relative to today', () async {
    final repository = FakeBillRepository();

    await seedSampleBills(repository, today: today);

    final bills = await repository.getAll();
    expect(bills, hasLength(10));
    expect(bills.where((b) => b.isPaid), hasLength(2));
    expect(
      bills.where((b) => !b.isPaid).map((b) => b.daysUntilDue(today)),
      containsAll([-2, 0, 1, 3]),
    );
  });

  test('bills a period one month before its due date', () async {
    final repository = FakeBillRepository();

    await seedSampleBills(repository, today: today);

    for (final bill in await repository.getAll()) {
      final expected = DateTime(bill.dueDate.year, bill.dueDate.month - 1);
      expect(
        (bill.periodYear, bill.periodMonth),
        (expected.year, expected.month),
      );
    }
  });

  test('applies the tiered water tariff', () async {
    final repository = FakeBillRepository();

    await seedSampleBills(repository, today: today);

    final bills = await repository.getAll();
    int amountFor(int usage) =>
        bills.firstWhere((b) => b.usageM3 == usage).amount;
    expect(amountFor(9), 15000 + 9 * 4300);
    expect(amountFor(16), 15000 + 10 * 4300 + 6 * 5700);
    expect(amountFor(27), 15000 + 10 * 4300 + 10 * 5700 + 7 * 7200);
  });

  test('leaves an existing database alone', () async {
    final repository = FakeBillRepository();
    await seedSampleBills(repository, today: today);

    await seedSampleBills(repository, today: today);

    expect(await repository.getAll(), hasLength(10));
  });
}
