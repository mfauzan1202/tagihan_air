import 'package:tagihan_air/models/bill.dart';

Bill testBill({
  required int id,
  required DateTime dueDate,
  String customerNumber = '0113002451',
  String customerName = 'Siti Rahmawati',
  int periodYear = 2026,
  int periodMonth = 10,
  int usageM3 = 16,
  int amount = 98200,
  BillStatus status = BillStatus.unpaid,
}) {
  return Bill(
    id: id,
    customerNumber: customerNumber,
    customerName: customerName,
    periodYear: periodYear,
    periodMonth: periodMonth,
    usageM3: usageM3,
    amount: amount,
    dueDate: dueDate,
    status: status,
    paidAt: status == BillStatus.paid ? dueDate : null,
  );
}
