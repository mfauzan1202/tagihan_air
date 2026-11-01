import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagihan_air/data/bill_repository.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/state/database_providers.dart';

final billsProvider = AsyncNotifierProvider<BillsNotifier, List<Bill>>(
  BillsNotifier.new,
);

final billProvider = FutureProvider.autoDispose.family<Bill?, int>((
  ref,
  id,
) async {
  final repository = ref.watch(billRepositoryProvider);
  await ref.watch(databaseReadyProvider.future);
  return repository.getById(id);
});

class BillsNotifier extends AsyncNotifier<List<Bill>> {
  @override
  Future<List<Bill>> build() async {
    final repository = ref.watch(billRepositoryProvider);
    await ref.watch(databaseReadyProvider.future);
    return repository.getAll();
  }

  BillRepository get _repository => ref.read(billRepositoryProvider);

  Future<Bill> add(BillDraft draft) async {
    final bill = await _repository.add(draft);
    ref.invalidateSelf();
    return bill;
  }

  Future<Bill> edit(int id, BillDraft draft) async {
    final bill = await _repository.update(id, draft);
    _refresh(id);
    return bill;
  }

  Future<Bill> markPaid(int id) async {
    final bill = await _repository.markPaid(id);
    _refresh(id);
    return bill;
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _refresh(id);
  }

  void _refresh(int id) {
    ref.invalidateSelf();
    ref.invalidate(billProvider(id));
  }
}
