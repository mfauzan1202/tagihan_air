import 'package:postgres/postgres.dart';

const _migrations = <List<String>>[
  [
    '''
    CREATE TABLE bills (
      id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      customer_number text NOT NULL,
      customer_name text NOT NULL,
      period_year smallint NOT NULL,
      period_month smallint NOT NULL CHECK (period_month BETWEEN 1 AND 12),
      usage_m3 integer NOT NULL CHECK (usage_m3 >= 0),
      amount bigint NOT NULL CHECK (amount > 0),
      due_date date NOT NULL,
      status text NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'paid')),
      paid_at timestamptz,
      created_at timestamptz NOT NULL DEFAULT now(),
      CONSTRAINT bills_customer_period_key
        UNIQUE (customer_number, period_year, period_month),
      CONSTRAINT bills_paid_at_matches_status
        CHECK ((status = 'paid') = (paid_at IS NOT NULL))
    )
    ''',
    'CREATE INDEX bills_due_date_idx ON bills (due_date)',
  ],
];

Future<void> migrate(SessionExecutor db) {
  return db.runTx((tx) async {
    await tx.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version integer PRIMARY KEY,
        applied_at timestamptz NOT NULL DEFAULT now()
      )
    ''');
    final result = await tx.execute(
      'SELECT coalesce(max(version), 0) FROM schema_migrations',
    );
    final current = result.first.first as int;

    for (var version = current + 1; version <= _migrations.length; version++) {
      for (final statement in _migrations[version - 1]) {
        await tx.execute(statement);
      }
      await tx.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@v:int4)'),
        parameters: {'v': version},
      );
    }
  });
}
