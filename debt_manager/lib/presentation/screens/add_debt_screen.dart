import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final String customerId;
  const AddDebtScreen({super.key, required this.customerId});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.dangerColor,
            onPrimary: Colors.white,
            surface: AppTheme.cardBg,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final notifier = ref.read(transactionProvider(widget.customerId).notifier);
    final ok = await notifier.addDebt(
      amount: double.parse(_amountCtrl.text.trim()),
      description: _descCtrl.text.trim(),
      date: _date,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        context.pop();
      } else {
        final err = ref.read(transactionProvider(widget.customerId)).error ??
            'Failed to add debt';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(title: const Text('Add Debt')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Debt Amount (₹)',
                prefixIcon:
                    Icon(Icons.currency_rupee, color: AppTheme.textHint),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              style: TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description / Items',
                prefixIcon: Icon(Icons.notes, color: AppTheme.textHint),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description required'
                  : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FAF0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today,
                      color: AppTheme.textHint, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date',
                          style: TextStyle(
                              color: AppTheme.textHint, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(DateFormat('dd MMMM yyyy').format(_date),
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 15)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Debt',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
