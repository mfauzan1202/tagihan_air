import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tagihan_air/app.dart';
import 'package:tagihan_air/state/database_providers.dart';

import '../support/fake_bill_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<FakeBillRepository> openNewBillForm(WidgetTester tester) async {
    final repository = FakeBillRepository();
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
    await tester.tap(find.text('Tagihan'));
    await tester.pumpAndSettle();
    return repository;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('flags every required field', (tester) async {
    await openNewBillForm(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsNWidgets(4));
  });

  testWidgets('saves a new bill and goes back to the list', (tester) async {
    final repository = await openNewBillForm(tester);

    await tester.enterText(field('No. pelanggan'), '0118000412');
    await tester.enterText(field('Nama pelanggan'), 'Dimas Pratama');
    await tester.enterText(field('Pemakaian'), '14');
    await tester.enterText(field('Nominal'), '90800');
    expect(find.text('90.800'), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final saved = (await repository.getAll()).single;
    expect(saved.customerName, 'Dimas Pratama');
    expect(saved.usageM3, 14);
    expect(saved.amount, 90800);
    expect(find.text('Dimas Pratama'), findsOneWidget);
  });
}
