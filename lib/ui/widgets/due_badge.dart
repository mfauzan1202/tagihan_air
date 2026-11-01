import 'package:flutter/material.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/ui/formatting.dart';

class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final (background, foreground) = _colors(
      Theme.of(context).colorScheme,
      today,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        dueLabel(bill, today),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _colors(ColorScheme colors, DateTime today) {
    if (bill.isPaid) return (const Color(0xFFDDF3E2), const Color(0xFF1D5B2C));
    final days = bill.daysUntilDue(today);
    if (days < 0) return (colors.errorContainer, colors.onErrorContainer);
    if (days <= 3) return (const Color(0xFFFFE8C2), const Color(0xFF7A4600));
    return (colors.surfaceContainerHighest, colors.onSurfaceVariant);
  }
}
