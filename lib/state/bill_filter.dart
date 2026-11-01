import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/state/bill_providers.dart';

enum BillFilter {
  unpaid,
  paid,
  all;

  bool matches(Bill bill) => switch (this) {
    BillFilter.unpaid => !bill.isPaid,
    BillFilter.paid => bill.isPaid,
    BillFilter.all => true,
  };
}

final billFilterProvider = NotifierProvider<BillFilterNotifier, BillFilter>(
  BillFilterNotifier.new,
);

class BillFilterNotifier extends Notifier<BillFilter> {
  @override
  BillFilter build() => BillFilter.unpaid;

  void select(BillFilter filter) => state = filter;
}

final visibleBillsProvider = Provider<AsyncValue<List<Bill>>>((ref) {
  final filter = ref.watch(billFilterProvider);
  final bills = ref.watch(billsProvider);
  return bills.whenData((all) => all.where(filter.matches).toList());
});
