import 'package:tagihan_air/models/bill.dart';

abstract interface class BillRepository {
  Future<List<Bill>> getAll();

  Future<Bill?> getById(int id);

  Future<Bill> add(BillDraft draft);

  Future<Bill> update(int id, BillDraft draft);

  Future<Bill> markPaid(int id, {DateTime? paidAt});

  Future<void> delete(int id);
}

class BillNotFoundException implements Exception {
  const BillNotFoundException(this.id);

  final int id;

  @override
  String toString() => 'Tagihan #$id tidak ditemukan';
}

class DuplicateBillException implements Exception {
  const DuplicateBillException(this.draft);

  final BillDraft draft;

  @override
  String toString() =>
      'Tagihan ${draft.customerNumber} untuk periode '
      '${draft.periodMonth}/${draft.periodYear} sudah ada';
}
