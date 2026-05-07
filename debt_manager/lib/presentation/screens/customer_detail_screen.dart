import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/debt_model.dart';
import '../../providers/debt_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final match = customers.where((c) => c.id == customerId).toList();
    if (match.isEmpty) {
      return const Scaffold(body: Center(child: Text('Customer not found')));
    }
    final customer = match.first;
    final debts = ref.watch(customerDebtsProvider(customerId));
    final unpaid = debts.where((d) => !d.isPaid).toList();
    final paid = debts.where((d) => d.isPaid).toList();
    final totalOwed = unpaid.fold(0.0, (s, d) => s + d.amount);

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(customer.name,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(customer.phone,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: totalOwed > 0
                  ? AppTheme.dangerColor.withOpacity(0.08)
                  : AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: totalOwed > 0
                    ? AppTheme.dangerColor.withOpacity(0.3)
                    : AppTheme.borderColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount Owed',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                Text(
                  '₹${totalOwed.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: totalOwed > 0
                        ? AppTheme.dangerColor
                        : AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Pending ──────────────────────────────────────
          if (unpaid.isNotEmpty) ...[
            Text('Pending Debts',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...unpaid.map((d) => _DebtTile(
                  debt: d,
                  onPaid: () =>
                      ref.read(debtActionsProvider).markPaid(customerId, d.id),
                  onDelete: () => ref
                      .read(debtActionsProvider)
                      .deleteDebt(customerId, d.id),
                )),
          ],

          // ── Cleared ──────────────────────────────────────
          if (paid.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Cleared Debts',
                style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
            const SizedBox(height: 8),
            ...paid.map((d) => _DebtTile(
                  debt: d,
                  isPaid: true,
                  onDelete: () => ref
                      .read(debtActionsProvider)
                      .deleteDebt(customerId, d.id),
                )),
          ],

          if (debts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No debts yet. Tap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customer/$customerId/add-debt'),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback? onPaid;
  final VoidCallback onDelete;
  final bool isPaid;

  const _DebtTile({
    required this.debt,
    this.onPaid,
    required this.onDelete,
    this.isPaid = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPaid ? AppTheme.primaryGreen : AppTheme.dangerColor,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debt.description,
                      style: TextStyle(
                        color:
                            isPaid ? AppTheme.textHint : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                      )),
                  const SizedBox(height: 3),
                  Text(DateFormat('dd MMM yyyy').format(debt.date),
                      style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '₹${debt.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isPaid ? AppTheme.textHint : AppTheme.dangerColor,
              ),
            ),
            if (!isPaid && onPaid != null)
              IconButton(
                icon: Icon(Icons.check_circle_outline,
                    color: AppTheme.primaryGreen),
                onPressed: onPaid,
                tooltip: 'Mark paid',
              ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.textHint),
              onPressed: onDelete,
            ),
          ],
        ),
      );
}
