enum BillStatus { unpaid, paid }

class Bill {
  const Bill({
    required this.id,
    required this.customerNumber,
    required this.customerName,
    required this.periodYear,
    required this.periodMonth,
    required this.usageM3,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAt,
  });

  final int id;
  final String customerNumber;
  final String customerName;
  final int periodYear;
  final int periodMonth;
  final int usageM3;
  final int amount;
  final DateTime dueDate;
  final BillStatus status;
  final DateTime? paidAt;

  bool get isPaid => status == BillStatus.paid;

  int daysUntilDue(DateTime today) {
    final due = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
    final from = DateTime.utc(today.year, today.month, today.day);
    return due.difference(from).inDays;
  }

  bool isOverdue(DateTime today) => !isPaid && daysUntilDue(today) < 0;

  BillDraft toDraft() => BillDraft(
    customerNumber: customerNumber,
    customerName: customerName,
    periodYear: periodYear,
    periodMonth: periodMonth,
    usageM3: usageM3,
    amount: amount,
    dueDate: dueDate,
  );
}

class BillDraft {
  const BillDraft({
    required this.customerNumber,
    required this.customerName,
    required this.periodYear,
    required this.periodMonth,
    required this.usageM3,
    required this.amount,
    required this.dueDate,
  });

  final String customerNumber;
  final String customerName;
  final int periodYear;
  final int periodMonth;
  final int usageM3;
  final int amount;
  final DateTime dueDate;
}
