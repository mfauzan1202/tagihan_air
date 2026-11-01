import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tagihan_air/app.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/state/database_providers.dart';

import '../support/fake_bill_repository.dart';
import '../support/test_bills.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final now = DateTime.now();
  DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);

  final bills = [
    testBill(
      id: 1,
      customerNumber: '0115000736',
      customerName: 'Fajar Nugroho',
      dueDate: inDays(3),
    ),
    testBill(id: 2, customerName: 'Siti Rahmawati', dueDate: inDays(-2)),
    testBill(
      id: 3,
      customerNumber: '0116003347',
      customerName: 'Rina Marlina',
      dueDate: inDays(-12),
      status: BillStatus.paid,
    ),
  ];

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billRepositoryProvider.overrideWithValue(FakeBillRepository(bills)),
          databaseReadyProvider.overrideWith((ref) async {}),
        ],
        child: const TagihanAirApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists unpaid bills by due date with due labels', (tester) async {
    await pumpApp(tester);

    expect(find.text('Terlambat 2 hari'), findsOneWidget);
    expect(find.text('3 hari lagi'), findsOneWidget);
    expect(find.text('Rina Marlina'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Siti Rahmawati')).dy,
      lessThan(tester.getTopLeft(find.text('Fajar Nugroho')).dy),
    );
  });

  testWidgets('shows only paid bills under the Lunas filter', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Lunas'));
    await tester.pumpAndSettle();

    expect(find.text('Rina Marlina'), findsOneWidget);
    expect(find.text('Siti Rahmawati'), findsNothing);
  });
}
