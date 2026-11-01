import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tagihan_air/data/bill_repository.dart';
import 'package:tagihan_air/models/bill.dart';
import 'package:tagihan_air/state/bill_providers.dart';
import 'package:tagihan_air/ui/formatting.dart';
import 'package:tagihan_air/ui/screens/bill_not_found_screen.dart';
import 'package:tagihan_air/ui/widgets/error_view.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key, this.bill});

  final Bill? bill;

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerNumber;
  late final TextEditingController _customerName;
  late final TextEditingController _usage;
  late final TextEditingController _amount;
  late final TextEditingController _dueDateText;
  late int _periodYear;
  late int _periodMonth;
  late DateTime _dueDate;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);

    _customerNumber = TextEditingController(text: bill?.customerNumber);
    _customerName = TextEditingController(text: bill?.customerName);
    _usage = TextEditingController(text: bill?.usageM3.toString());
    _amount = TextEditingController(
      text: bill == null ? null : formatThousands(bill.amount),
    );
    _periodYear = bill?.periodYear ?? lastMonth.year;
    _periodMonth = bill?.periodMonth ?? lastMonth.month;
    _dueDate = bill?.dueDate ?? DateTime(_periodYear, _periodMonth + 1, 20);
    _dueDateText = TextEditingController(text: formatLongDate(_dueDate));
  }

  @override
  void dispose() {
    _customerNumber.dispose();
    _customerName.dispose();
    _usage.dispose();
    _amount.dispose();
    _dueDateText.dispose();
    super.dispose();
  }

  List<int> get _years {
    final now = DateTime.now().year;
    return {for (var y = now - 2; y <= now + 1; y++) y, _periodYear}.toList()
      ..sort();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(_dueDate.year - 2),
      lastDate: DateTime(_dueDate.year + 2, 12, 31),
      helpText: 'Jatuh tempo',
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _dueDateText.text = formatLongDate(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final draft = BillDraft(
      customerNumber: _customerNumber.text.trim(),
      customerName: _customerName.text.trim(),
      periodYear: _periodYear,
      periodMonth: _periodMonth,
      usageM3: int.parse(_usage.text),
      amount: parseRupiah(_amount.text)!,
      dueDate: _dueDate,
    );
    final bills = ref.read(billsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.bill;

    setState(() => _saving = true);
    try {
      if (existing == null) {
        await bills.add(draft);
      } else {
        await bills.edit(existing.id, draft);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Tagihan ditambahkan' : 'Perubahan disimpan',
          ),
        ),
      );
      if (mounted) context.pop();
    } on DuplicateBillException {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No. ${draft.customerNumber} sudah punya tagihan periode '
            '${formatPeriod(draft.periodYear, draft.periodMonth)}.',
          ),
        ),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tagihan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bill == null ? 'Tagihan baru' : 'Edit tagihan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _customerNumber,
              decoration: const InputDecoration(
                labelText: 'No. pelanggan',
                hintText: '0113002451',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: (value) {
                final number = value?.trim() ?? '';
                if (number.isEmpty) return 'Wajib diisi';
                if (number.length < 6) return 'Minimal 6 digit';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerName,
              decoration: const InputDecoration(labelText: 'Nama pelanggan'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value?.trim() ?? '').isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: _periodMonth,
                    decoration: const InputDecoration(labelText: 'Periode'),
                    items: [
                      for (var month = 1; month <= 12; month++)
                        DropdownMenuItem(
                          value: month,
                          child: Text(formatMonth(month)),
                        ),
                    ],
                    onChanged: (month) => setState(() => _periodMonth = month!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _periodYear,
                    decoration: const InputDecoration(labelText: 'Tahun'),
                    items: [
                      for (final year in _years)
                        DropdownMenuItem(value: year, child: Text('$year')),
                    ],
                    onChanged: (year) => setState(() => _periodYear = year!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usage,
              decoration: const InputDecoration(
                labelText: 'Pemakaian',
                suffixText: 'm³',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsSeparatorFormatter()],
              validator: (value) {
                final amount = parseRupiah(value ?? '');
                if (amount == null) return 'Wajib diisi';
                if (amount == 0) return 'Nominal harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dueDateText,
              readOnly: true,
              onTap: _pickDueDate,
              decoration: const InputDecoration(
                labelText: 'Jatuh tempo',
                suffixIcon: Icon(Icons.event_outlined),
              ),
              validator: (_) =>
                  _dueDate.isBefore(DateTime(_periodYear, _periodMonth + 1))
                  ? 'Harus setelah periode '
                        '${formatPeriod(_periodYear, _periodMonth)}'
                  : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ),
      ),
    );
  }
}

class EditBillScreen extends ConsumerWidget {
  const EditBillScreen({super.key, required this.billId});

  final int billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(billProvider(billId))
        .when(
          data: (bill) => bill == null
              ? const BillNotFoundScreen()
              : BillFormScreen(bill: bill),
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
