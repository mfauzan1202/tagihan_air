import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagihan_air/state/bill_filter.dart';
import 'package:tagihan_air/state/bill_providers.dart';
import 'package:tagihan_air/state/database_providers.dart';
import 'package:tagihan_air/ui/widgets/bill_tile.dart';
import 'package:tagihan_air/ui/widgets/error_view.dart';
import 'package:tagihan_air/ui/widgets/status_filter_bar.dart';

class BillListScreen extends ConsumerWidget {
  const BillListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(visibleBillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan Air')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(width: double.infinity, child: StatusFilterBar()),
          ),
          Expanded(
            child: bills.when(
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(billsProvider.future),
                child: items.isEmpty
                    ? _EmptyList(filter: ref.watch(billFilterProvider))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (context, index) =>
                            BillTile(bill: items[index]),
                      ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message:
                    'Tidak bisa terhubung ke database '
                    '${ref.read(databaseConfigProvider)}.',
                onRetry: () => ref.invalidate(databaseReadyProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.filter});

  final BillFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      BillFilter.unpaid => 'Semua tagihan sudah lunas.',
      BillFilter.paid => 'Belum ada tagihan yang lunas.',
      BillFilter.all => 'Belum ada tagihan.',
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
