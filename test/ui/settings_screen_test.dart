import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tagihan_air/app.dart';
import 'package:tagihan_air/data/database.dart';
import 'package:tagihan_air/state/database_providers.dart';

import '../support/fake_bill_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('shows app version and database target', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Tagihan Air',
      packageName: 'com.mfauzan.tagihanAir',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billRepositoryProvider.overrideWithValue(FakeBillRepository()),
          databaseReadyProvider.overrideWith((ref) async {}),
          databaseConfigProvider.overrideWithValue(
            const DatabaseConfig(
              host: 'localhost',
              port: 5435,
              database: 'tagihan_air',
              username: 'tagihan',
              password: 'tagihan',
            ),
          ),
        ],
        child: const TagihanAirApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();

    expect(find.text('0.1.0 (1)'), findsOneWidget);
    expect(find.text('localhost:5435/tagihan_air'), findsOneWidget);
  });
}
