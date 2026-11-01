import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/state/bill_providers.dart';
import 'package:tagihan_air/ui/formatting.dart';
import 'package:tagihan_air/ui/screens/bill_not_found_screen.dart';
import 'package:tagihan_air/ui/widgets/confirm_dialog.dart';
import 'package:tagihan_air/ui/widgets/due_badge.dart';
import 'package:tagihan_air/ui/widgets/error_view.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});

  final int billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(billProvider(billId))
        .when(
          data: (bill) => bill == null
              ? const BillNotFoundScreen()
              : _BillDetail(bill: bill),
          loading: () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: 'Tagihan belum bisa dimuat.',
              onRetry: () => ref.invalidate(billProvider(billId)),
            ),
          ),
        );
  }
}

class _BillDetail extends ConsumerWidget {
  const _BillDetail({required this.bill});

  final Bill bill;

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(billsProvider.notifier).markPaid(bill.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Tagihan ditandai lunas')),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus tagihan?',
      message:
          'Tagihan ${bill.customerName} periode '
          '${formatPeriod(bill.periodYear, bill.periodMonth)} '
          'akan dihapus permanen.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !context.mounted) return;

    final bills = ref.read(billsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    try {
      await bills.delete(bill.id);
      messenger.showSnackBar(const SnackBar(content: Text('Tagihan dihapus')));
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paidAt = bill.paidAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail tagihan'),
        actions: [
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.customerName, style: theme.textTheme.headlineSmall),
                Text(
                  'No. pelanggan ${bill.customerNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  formatRupiah(bill.amount),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DueBadge(bill: bill),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          _Row(
            label: 'Periode',
            value: formatPeriod(bill.periodYear, bill.periodMonth),
          ),
          _Row(label: 'Pemakaian', value: '${bill.usageM3} m³'),
          _Row(label: 'Jatuh tempo', value: formatLongDate(bill.dueDate)),
          _Row(label: 'Status', value: bill.isPaid ? 'Lunas' : 'Belum bayar'),
          if (paidAt != null)
            _Row(label: 'Tanggal bayar', value: formatLongDate(paidAt)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/bills/${bill.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              if (!bill.isPaid) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _markPaid(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('Tandai lunas'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(value, style: theme.textTheme.bodyLarge),
    );
  }
}
