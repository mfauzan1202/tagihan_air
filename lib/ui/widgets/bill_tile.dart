import 'package:flutter/material.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/ui/formatting.dart';
import 'package:tagihan_air/ui/widgets/due_badge.dart';

class BillTile extends StatelessWidget {
  const BillTile({super.key, required this.bill, this.onTap});

  final Bill bill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.customerName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${bill.customerNumber} · '
                    '${formatPeriod(bill.periodYear, bill.periodMonth)}',
                    style: secondary,
                  ),
                  Text(
                    'Jatuh tempo ${formatDate(bill.dueDate)}',
                    style: secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupiah(bill.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DueBadge(bill: bill),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
