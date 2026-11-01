import 'package:tagihan_air/data/bill_repository.dart';
import 'package:tagihan_air/models/bill.dart';

class FakeBillRepository implements BillRepository {
  FakeBillRepository([List<Bill> bills = const []]) : _bills = [...bills] {
    _nextId = _bills.fold(0, (max, b) => b.id > max ? b.id : max) + 1;
  }

  final List<Bill> _bills;
  late int _nextId;

  @override
  Future<List<Bill>> getAll() async =>
      [..._bills]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  @override
  Future<Bill?> getById(int id) async =>
      _bills.where((b) => b.id == id).firstOrNull;

  @override
  Future<Bill> add(BillDraft draft) async {
    _checkDuplicate(draft);
    final bill = _fromDraft(_nextId++, draft, BillStatus.unpaid, null);
    _bills.add(bill);
    return bill;
  }

  @override
  Future<Bill> update(int id, BillDraft draft) async {
    final index = _indexOf(id);
    _checkDuplicate(draft, ignoreId: id);
    final current = _bills[index];
    return _bills[index] = _fromDraft(
      id,
      draft,
      current.status,
      current.paidAt,
    );
  }

  @override
  Future<Bill> markPaid(int id, {DateTime? paidAt}) async {
    final index = _indexOf(id);
    final current = _bills[index];
    return _bills[index] = _fromDraft(
      id,
      current.toDraft(),
      BillStatus.paid,
      current.paidAt ?? paidAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> delete(int id) async => _bills.removeWhere((b) => b.id == id);

  int _indexOf(int id) {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index == -1) throw BillNotFoundException(id);
    return index;
  }

  void _checkDuplicate(BillDraft draft, {int? ignoreId}) {
    final exists = _bills.any(
      (b) =>
          b.id != ignoreId &&
          b.customerNumber == draft.customerNumber &&
          b.periodYear == draft.periodYear &&
          b.periodMonth == draft.periodMonth,
    );
    if (exists) throw DuplicateBillException(draft);
  }

  Bill _fromDraft(int id, BillDraft d, BillStatus status, DateTime? paidAt) {
    return Bill(
      id: id,
      customerNumber: d.customerNumber,
      customerName: d.customerName,
      periodYear: d.periodYear,
      periodMonth: d.periodMonth,
      usageM3: d.usageM3,
      amount: d.amount,
      dueDate: d.dueDate,
      status: status,
      paidAt: paidAt,
    );
  }
}
