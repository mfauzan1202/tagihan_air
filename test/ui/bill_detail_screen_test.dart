import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tagihan_air/app.dart';
import 'package:tagihan_air/router.dart';
import 'package:tagihan_air/state/database_providers.dart';

import '../support/fake_bill_repository.dart';
import '../support/test_bills.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final now = DateTime.now();

  Future<FakeBillRepository> openBill(WidgetTester tester, int id) async {
    final repository = FakeBillRepository([
      testBill(
        id: 7,
        customerName: 'Hendra Wijaya',
        customerNumber: '0114001188',
        dueDate: DateTime(now.year, now.month, now.day + 5),
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billRepositoryProvider.overrideWithValue(repository),
          databaseReadyProvider.overrideWith((ref) async {}),
        ],
        child: const TagihanAirApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TagihanAirApp)),
    );
    container.read(routerProvider).go('/bills/$id');
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('opens a bill straight from its id', (tester) async {
    await openBill(tester, 7);

    expect(find.text('Detail tagihan'), findsOneWidget);
    expect(find.text('Hendra Wijaya'), findsOneWidget);
    expect(find.text('5 hari lagi'), findsOneWidget);
  });

  testWidgets('marks the bill as paid', (tester) async {
    final repository = await openBill(tester, 7);

    await tester.tap(find.text('Tandai lunas'));
    await tester.pumpAndSettle();

    expect((await repository.getById(7))!.isPaid, isTrue);
    expect(find.text('Tandai lunas'), findsNothing);
    expect(find.text('Tanggal bayar'), findsOneWidget);
  });

  testWidgets('deletes only after confirmation', (tester) async {
    final repository = await openBill(tester, 7);

    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(await repository.getById(7), isNotNull);

    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(await repository.getById(7), isNull);
    expect(find.text('Tagihan Air'), findsOneWidget);
    expect(find.text('Hendra Wijaya'), findsNothing);
  });

  testWidgets('shows a not-found screen for an unknown id', (tester) async {
    await openBill(tester, 99);

    expect(
      find.text('Tagihan tidak ditemukan. Mungkin sudah dihapus.'),
      findsOneWidget,
    );
  });
}
