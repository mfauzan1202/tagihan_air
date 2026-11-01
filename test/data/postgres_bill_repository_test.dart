@Tags(['postgres'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:postgres/postgres.dart';
import 'package:tagihan_air/data/bill_repository.dart';
import 'package:tagihan_air/data/database.dart';
import 'package:tagihan_air/data/migrations.dart';
import 'package:tagihan_air/data/postgres_bill_repository.dart';
import 'package:tagihan_air/models/bill.dart';

BillDraft _draft({
  String customerNumber = '0113002451',
  String customerName = 'Siti Rahmawati',
  int periodMonth = 10,
  DateTime? dueDate,
  int amount = 98200,
}) {
  return BillDraft(
    customerNumber: customerNumber,
    customerName: customerName,
    periodYear: 2026,
    periodMonth: periodMonth,
    usageM3: 16,
    amount: amount,
    dueDate: dueDate ?? DateTime(2026, 11, 20),
  );
}

void main() {
  late Pool<void> pool;
  late PostgresBillRepository repository;

  setUpAll(() async {
    final env = Platform.environment;
    pool = openPool(
      DatabaseConfig(
        host: env['TEST_DB_HOST'] ?? 'localhost',
        port: int.parse(env['TEST_DB_PORT'] ?? '5435'),
        database: env['TEST_DB_NAME'] ?? 'tagihan_air_test',
        username: 'tagihan',
        password: 'tagihan',
      ),
    );
    await pool.execute('DROP TABLE IF EXISTS bills, schema_migrations');
    await migrate(pool);
    repository = PostgresBillRepository(pool);
  });

  tearDownAll(() => pool.close());

  setUp(() => pool.execute('TRUNCATE bills RESTART IDENTITY'));

  test('migrate is safe to run again', () async {
    await migrate(pool);

    final versions = await pool.execute(
      'SELECT version FROM schema_migrations',
    );
    expect(versions, hasLength(1));
  });

  test('add stores a new bill as unpaid', () async {
    final bill = await repository.add(_draft());

    expect(bill.id, greaterThan(0));
    expect(bill.status, BillStatus.unpaid);
    expect(bill.paidAt, isNull);
    expect(bill.customerName, 'Siti Rahmawati');
    expect(bill.amount, 98200);
  });

  test('keeps the due date on the same calendar day', () async {
    final bill = await repository.add(_draft(dueDate: DateTime(2026, 11, 20)));
    final reloaded = await repository.getById(bill.id);

    expect(reloaded!.dueDate, DateTime(2026, 11, 20));
  });

  test('getAll returns bills ordered by due date', () async {
    await repository.add(
      _draft(customerNumber: '0000000001', dueDate: DateTime(2026, 11, 25)),
    );
    await repository.add(
      _draft(customerNumber: '0000000002', dueDate: DateTime(2026, 11, 3)),
    );
    await repository.add(
      _draft(customerNumber: '0000000003', dueDate: DateTime(2026, 11, 14)),
    );

    final bills = await repository.getAll();

    expect(bills.map((b) => b.customerNumber), [
      '0000000002',
      '0000000003',
      '0000000001',
    ]);
  });

  test('getById returns null for an unknown id', () async {
    expect(await repository.getById(999), isNull);
  });

  test('update replaces the editable fields', () async {
    final bill = await repository.add(_draft());

    final updated = await repository.update(
      bill.id,
      _draft(customerName: 'Siti R.', amount: 101500),
    );

    expect(updated.id, bill.id);
    expect(updated.customerName, 'Siti R.');
    expect(updated.amount, 101500);
  });

  test('update throws for an unknown id', () {
    expect(
      () => repository.update(999, _draft()),
      throwsA(isA<BillNotFoundException>()),
    );
  });

  test('rejects a second bill for the same customer and period', () async {
    await repository.add(_draft());

    expect(
      () => repository.add(_draft(customerName: 'Nama lain')),
      throwsA(isA<DuplicateBillException>()),
    );
  });

  test('markPaid keeps the first payment time', () async {
    final bill = await repository.add(_draft());
    final firstPayment = DateTime(2026, 11, 18, 9, 30);

    final paid = await repository.markPaid(bill.id, paidAt: firstPayment);
    final paidAgain = await repository.markPaid(
      bill.id,
      paidAt: DateTime(2026, 11, 19),
    );

    expect(paid.status, BillStatus.paid);
    expect(paid.paidAt, firstPayment);
    expect(paidAgain.paidAt, firstPayment);
  });

  test('markPaid throws for an unknown id', () {
    expect(
      () => repository.markPaid(999),
      throwsA(isA<BillNotFoundException>()),
    );
  });

  test('delete removes the bill', () async {
    final bill = await repository.add(_draft());

    await repository.delete(bill.id);

    expect(await repository.getById(bill.id), isNull);
  });
}
