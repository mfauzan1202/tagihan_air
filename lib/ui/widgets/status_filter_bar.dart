import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagihan_air/state/bill_filter.dart';

class StatusFilterBar extends ConsumerWidget {
  const StatusFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(billFilterProvider);

    return SegmentedButton<BillFilter>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: BillFilter.unpaid, label: Text('Belum bayar')),
        ButtonSegment(value: BillFilter.paid, label: Text('Lunas')),
        ButtonSegment(value: BillFilter.all, label: Text('Semua')),
      ],
      selected: {selected},
      onSelectionChanged: (value) =>
          ref.read(billFilterProvider.notifier).select(value.single),
    );
  }
}
