import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/credit_model.dart';
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
    final credits = ref.watch(customerCreditsProvider(customerId));
    final repo = ref.read(repositoryProvider);

    final unpaid = debts.where((d) => !d.isPaid).toList();
    final paid = debts.where((d) => d.isPaid).toList();
    final totalDebt = unpaid.fold(0.0, (s, d) => s + d.amount);
    final totalCredit = credits.fold(0.0, (s, c) => s + c.amount);
    final netBalance = repo.getNetBalanceForCustomer(customerId);

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ── Balance Summary ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: netBalance > 0
                  ? AppTheme.dangerColor.withOpacity(0.07)
                  : AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: netBalance > 0
                    ? AppTheme.dangerColor.withOpacity(0.25)
                    : AppTheme.borderColor,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net Outstanding',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '₹${netBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: netBalance > 0
                            ? AppTheme.dangerColor
                            : AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Total Debt',
                        value: '₹${totalDebt.toStringAsFixed(2)}',
                        color: AppTheme.dangerColor,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'Total Credit',
                        value: '₹${totalCredit.toStringAsFixed(2)}',
                        color: AppTheme.primaryGreen,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Pending Debts ───────────────────────────────
          if (unpaid.isNotEmpty) ...[
            _SectionHeader(
              label: 'Pending Debts',
              color: AppTheme.dangerColor,
              icon: Icons.arrow_upward_rounded,
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
            const SizedBox(height: 16),
          ],

          // ── Credits ─────────────────────────────────────
          if (credits.isNotEmpty) ...[
            _SectionHeader(
              label: 'Credits Received',
              color: AppTheme.primaryGreen,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(height: 8),
            ...credits.map((c) => _CreditTile(
                  credit: c,
                  onDelete: () => ref
                      .read(debtActionsProvider)
                      .deleteCredit(customerId, c.id),
                )),
            const SizedBox(height: 16),
          ],

          // ── Cleared Debts ───────────────────────────────
          if (paid.isNotEmpty) ...[
            _SectionHeader(
              label: 'Cleared Debts',
              color: AppTheme.textHint,
              icon: Icons.check_circle_outline,
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

          if (debts.isEmpty && credits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No records yet.\nTap + to add a debt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textHint, fontSize: 14),
                ),
              ),
            ),
        ],
      ),

      // ── Dual FABs ───────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'credit_fab',
              onPressed: () => context.push('/customer/$customerId/add-credit'),
              backgroundColor: AppTheme.cardBg,
              elevation: 2,
              icon: Icon(Icons.arrow_downward_rounded,
                  color: AppTheme.primaryGreen),
              label: Text('Add Credit',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600)),
            ),
            FloatingActionButton.extended(
              heroTag: 'debt_fab',
              onPressed: () => context.push('/customer/$customerId/add-debt'),
              backgroundColor: AppTheme.dangerColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Debt',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      );
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
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
                  const SizedBox(height: 2),
                  Text(DateFormat('dd MMM yyyy').format(debt.date),
                      style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
            ),
            Text('₹${debt.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isPaid ? AppTheme.textHint : AppTheme.dangerColor,
                )),
            if (!isPaid && onPaid != null)
              IconButton(
                icon: Icon(Icons.check_circle_outline,
                    color: AppTheme.primaryGreen, size: 20),
                onPressed: onPaid,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: AppTheme.textHint, size: 20),
              onPressed: onDelete,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}

class _CreditTile extends StatelessWidget {
  final CreditModel credit;
  final VoidCallback onDelete;

  const _CreditTile({required this.credit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(credit.description,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(DateFormat('dd MMM yyyy').format(credit.date),
                      style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
            ),
            Text('- ₹${credit.amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.primaryGreen)),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: AppTheme.textHint, size: 20),
              onPressed: onDelete,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}
