import 'dart:math';

import 'package:tagihan_air/data/bill_repository.dart';
import 'package:tagihan_air/models/bill.dart';

class _Sample {
  const _Sample(
    this.number,
    this.name, {
    required this.usage,
    required this.dueIn,
    this.paid = false,
  });

  final String number;
  final String name;
  final int usage;
  final int dueIn;
  final bool paid;
}

const _samples = [
  _Sample('0113004873', 'Agus Setiawan', usage: 21, dueIn: -33),
  _Sample('0113002451', 'Siti Rahmawati', usage: 16, dueIn: -2),
  _Sample('0114001188', 'Hendra Wijaya', usage: 27, dueIn: 0),
  _Sample('0114003902', 'Maya Puspita', usage: 12, dueIn: 1),
  _Sample('0113004873', 'Agus Setiawan', usage: 19, dueIn: 3),
  _Sample('0115000736', 'Fajar Nugroho', usage: 33, dueIn: 6),
  _Sample('0115002214', 'Lina Kartika', usage: 9, dueIn: 12),
  _Sample('0116000521', 'Yusuf Hidayat', usage: 24, dueIn: 19),
  _Sample('0116003347', 'Rina Marlina', usage: 15, dueIn: -12, paid: true),
  _Sample('0117001065', 'Bambang Prakoso', usage: 22, dueIn: -25, paid: true),
];

Future<void> seedSampleBills(
  BillRepository repository, {
  DateTime? today,
}) async {
  if ((await repository.getAll()).isNotEmpty) return;

  final now = today ?? DateTime.now();
  for (final sample in _samples) {
    final due = DateTime(now.year, now.month, now.day + sample.dueIn);
    final period = DateTime(due.year, due.month - 1);
    final bill = await repository.add(
      BillDraft(
        customerNumber: sample.number,
        customerName: sample.name,
        periodYear: period.year,
        periodMonth: period.month,
        usageM3: sample.usage,
        amount: _charge(sample.usage),
        dueDate: due,
      ),
    );
    if (sample.paid) {
      await repository.markPaid(
        bill.id,
        paidAt: DateTime(due.year, due.month, due.day - 3, 10, 15),
      );
    }
  }
}

int _charge(int usageM3) {
  final firstTier = min(usageM3, 10);
  final secondTier = min(max(usageM3 - 10, 0), 10);
  final rest = max(usageM3 - 20, 0);
  return 15000 + firstTier * 4300 + secondTier * 5700 + rest * 7200;
}
