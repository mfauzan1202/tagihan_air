import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgres/postgres.dart';
import 'package:tagihan_air/data/bill_repository.dart';
import 'package:tagihan_air/data/database.dart';
import 'package:tagihan_air/data/migrations.dart';
import 'package:tagihan_air/data/postgres_bill_repository.dart';
import 'package:tagihan_air/data/sample_bills.dart';

final databaseConfigProvider = Provider<DatabaseConfig>(
  (ref) => DatabaseConfig.fromEnvironment(),
);

final databaseProvider = Provider<Pool<void>>((ref) {
  final pool = openPool(ref.watch(databaseConfigProvider));
  ref.onDispose(pool.close);
  return pool;
});

final billRepositoryProvider = Provider<BillRepository>(
  (ref) => PostgresBillRepository(ref.watch(databaseProvider)),
);

final databaseReadyProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  final repository = ref.watch(billRepositoryProvider);
  await migrate(db);
  await seedSampleBills(repository);
});
