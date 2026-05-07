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
    final customerList = customers.where((c) => c.id == customerId).toList();

    if (customerList.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Customer not found')),
      );
    }

    final customer = customerList.first;
    final debts = ref.watch(customerDebtsProvider(customerId));
    final unpaid = debts.where((d) => !d.isPaid).toList();
    final paid = debts.where((d) => d.isPaid).toList();
    final totalOwed = unpaid.fold(0.0, (s, d) => s + d.amount);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              customer.phone,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: totalOwed > 0
                  ? AppTheme.dangerColor.withOpacity(0.15)
                  : AppTheme.successColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: totalOwed > 0
                    ? AppTheme.dangerColor
                    : AppTheme.successColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount Owed',
                    style: TextStyle(color: Colors.white70)),
                Text(
                  '₹${totalOwed.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: totalOwed > 0
                        ? AppTheme.dangerColor
                        : AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Pending debts ────────────────────────────────
          if (unpaid.isNotEmpty) ...[
            const Text(
              'Pending Debts',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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

          // ── Cleared debts ────────────────────────────────
          if (paid.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Cleared Debts',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
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
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No debts yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customer/$customerId/add-debt'),
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Debt', style: TextStyle(color: Colors.white)),
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.description,
                  style: TextStyle(
                    color: isPaid ? Colors.white38 : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(debt.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₹${debt.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isPaid ? Colors.white38 : AppTheme.dangerColor,
            ),
          ),
          if (!isPaid && onPaid != null)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: onPaid,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
