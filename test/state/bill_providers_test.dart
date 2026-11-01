import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/state/bill_filter.dart';
import 'package:tagihan_air/state/bill_providers.dart';
import 'package:tagihan_air/state/database_providers.dart';

import '../support/fake_bill_repository.dart';
import '../support/test_bills.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    final repository = FakeBillRepository([
      testBill(id: 1, dueDate: DateTime(2026, 11, 20)),
      testBill(
        id: 2,
        customerNumber: '0117001065',
        dueDate: DateTime(2026, 10, 20),
        status: BillStatus.paid,
      ),
    ]);
    container = ProviderContainer.test(
      overrides: [
        billRepositoryProvider.overrideWithValue(repository),
        databaseReadyProvider.overrideWith((ref) async {}),
      ],
    );
  });

  List<int> visibleIds() => container
      .read(visibleBillsProvider)
      .requireValue
      .map((b) => b.id)
      .toList();

  test('shows unpaid bills by default and follows the filter', () async {
    await container.read(billsProvider.future);
    expect(visibleIds(), [1]);

    container.read(billFilterProvider.notifier).select(BillFilter.paid);
    expect(visibleIds(), [2]);

    container.read(billFilterProvider.notifier).select(BillFilter.all);
    expect(visibleIds(), [2, 1]);
  });

  test('markPaid refreshes both the list and the single bill', () async {
    container.listen(billProvider(1), (_, _) {});
    expect((await container.read(billProvider(1).future))!.isPaid, isFalse);

    await container.read(billsProvider.notifier).markPaid(1);

    final bills = await container.read(billsProvider.future);
    expect(bills.firstWhere((b) => b.id == 1).isPaid, isTrue);
    expect((await container.read(billProvider(1).future))!.isPaid, isTrue);
  });

  test('delete removes the bill from the list', () async {
    await container.read(billsProvider.future);

    await container.read(billsProvider.notifier).delete(1);

    final bills = await container.read(billsProvider.future);
    expect(bills.map((b) => b.id), [2]);
    expect(await container.read(billProvider(1).future), isNull);
  });
}
