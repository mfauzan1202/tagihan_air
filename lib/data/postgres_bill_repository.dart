import 'package:postgres/postgres.dart';
import 'package:tagihan_air/data/bill_repository.dart';
import 'package:tagihan_air/models/bill.dart';

class PostgresBillRepository implements BillRepository {
  PostgresBillRepository(this._db);

  final Session _db;

  static const _columns =
      'id, customer_number, customer_name, period_year, period_month, '
      'usage_m3, amount, due_date, status, paid_at';

  @override
  Future<List<Bill>> getAll() async {
    final result = await _db.execute(
      'SELECT $_columns FROM bills ORDER BY due_date, id',
    );
    return result.map(_toBill).toList();
  }

  @override
  Future<Bill?> getById(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT $_columns FROM bills WHERE id = @id:int4'),
      parameters: {'id': id},
    );
    return result.isEmpty ? null : _toBill(result.first);
  }

  @override
  Future<Bill> add(BillDraft draft) async {
    final result = await _rejectDuplicate(
      draft,
      () => _db.execute(
        Sql.named('''
          INSERT INTO bills (
            customer_number, customer_name, period_year, period_month,
            usage_m3, amount, due_date
          ) VALUES (
            @customer_number:text, @customer_name:text, @period_year:int2,
            @period_month:int2, @usage_m3:int4, @amount:int8, @due_date:date
          )
          RETURNING $_columns
        '''),
        parameters: _draftParameters(draft),
      ),
    );
    return _toBill(result.first);
  }

  @override
  Future<Bill> update(int id, BillDraft draft) async {
    final result = await _rejectDuplicate(
      draft,
      () => _db.execute(
        Sql.named('''
          UPDATE bills SET
            customer_number = @customer_number:text,
            customer_name = @customer_name:text,
            period_year = @period_year:int2,
            period_month = @period_month:int2,
            usage_m3 = @usage_m3:int4,
            amount = @amount:int8,
            due_date = @due_date:date
          WHERE id = @id:int4
          RETURNING $_columns
        '''),
        parameters: {..._draftParameters(draft), 'id': id},
      ),
    );
    if (result.isEmpty) throw BillNotFoundException(id);
    return _toBill(result.first);
  }

  @override
  Future<Bill> markPaid(int id, {DateTime? paidAt}) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE bills
        SET status = 'paid', paid_at = coalesce(paid_at, @paid_at:timestamptz)
        WHERE id = @id:int4
        RETURNING $_columns
      '''),
      parameters: {'id': id, 'paid_at': paidAt ?? DateTime.now()},
    );
    if (result.isEmpty) throw BillNotFoundException(id);
    return _toBill(result.first);
  }

  @override
  Future<void> delete(int id) async {
    await _db.execute(
      Sql.named('DELETE FROM bills WHERE id = @id:int4'),
      parameters: {'id': id},
    );
  }

  Future<Result> _rejectDuplicate(
    BillDraft draft,
    Future<Result> Function() query,
  ) async {
    try {
      return await query();
    } on ServerException catch (e) {
      if (e.constraintName == 'bills_customer_period_key') {
        throw DuplicateBillException(draft);
      }
      rethrow;
    }
  }

  Map<String, Object?> _draftParameters(BillDraft draft) => {
    'customer_number': draft.customerNumber,
    'customer_name': draft.customerName,
    'period_year': draft.periodYear,
    'period_month': draft.periodMonth,
    'usage_m3': draft.usageM3,
    'amount': draft.amount,
    'due_date': DateTime.utc(
      draft.dueDate.year,
      draft.dueDate.month,
      draft.dueDate.day,
    ),
  };

  Bill _toBill(ResultRow row) {
    final c = row.toColumnMap();
    final dueDate = c['due_date'] as DateTime;
    return Bill(
      id: c['id'] as int,
      customerNumber: c['customer_number'] as String,
      customerName: c['customer_name'] as String,
      periodYear: c['period_year'] as int,
      periodMonth: c['period_month'] as int,
      usageM3: c['usage_m3'] as int,
      amount: c['amount'] as int,
      dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day),
      status: BillStatus.values.byName(c['status'] as String),
      paidAt: (c['paid_at'] as DateTime?)?.toLocal(),
    );
  }
}
