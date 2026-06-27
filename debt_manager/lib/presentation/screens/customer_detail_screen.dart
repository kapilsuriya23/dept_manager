import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';
import 'package:printing/printing.dart';
import '../../data/services/pdf_service.dart';
import '../../providers/auth_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  Future<void> _downloadPdf(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> customer,
    TransactionState txState,
  ) async {
    final user = ref.read(authProvider).user;
    final shopName = user?.shopName ?? 'DebtBook';
    try {
      final pdfBytes = await PdfService.generateCustomerStatement(
        shopName: shopName,
        customer: customer,
        debts: txState.debts, // ← only debts, no credits
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name:
            '${customer['name']}_statement_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerState = ref.watch(customersProvider);
    final customer = customerState.customers.firstWhere(
      (c) => c['_id'] == customerId,
      orElse: () => <String, dynamic>{},
    );

    final txState = ref.watch(transactionProvider(customerId));
    final unpaid = txState.debts.where((d) => d['isPaid'] == false).toList();
    final paid = txState.debts.where((d) => d['isPaid'] == true).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer['name'] as String? ?? 'Customer',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(customer['phone'] as String? ?? '',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          if (txState.loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryGreen),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf_outlined,
                color: AppTheme.dangerColor),
            tooltip: 'Download Statement',
            onPressed: txState.loading
                ? null
                : () => _downloadPdf(context, ref, customer, txState),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () =>
                ref.read(transactionProvider(customerId).notifier).fetchAll(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () =>
            ref.read(transactionProvider(customerId).notifier).fetchAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ── Error ───────────────────────────────────────
            if (txState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(txState.error!,
                    style:
                        TextStyle(color: AppTheme.dangerColor, fontSize: 13)),
              ),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: txState.netBalance > 0
                    ? AppTheme.dangerColor.withOpacity(0.07)
                    : AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: txState.netBalance > 0
                      ? AppTheme.dangerColor.withOpacity(0.25)
                      : AppTheme.borderColor,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customer Address:',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(customer['address'] as String? ?? 'Not provided',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Balance Summary ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: txState.netBalance > 0
                    ? AppTheme.dangerColor.withOpacity(0.07)
                    : AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: txState.netBalance > 0
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
                        '₹${txState.netBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: txState.netBalance > 0
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
                          value: '₹${txState.totalDebt.toStringAsFixed(2)}',
                          color: AppTheme.dangerColor,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: 'Total Credit',
                          value: '₹${txState.totalCredit.toStringAsFixed(2)}',
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

            // ── Loading ─────────────────────────────────────
            if (txState.loading && txState.debts.isEmpty)
              const Center(child: CircularProgressIndicator()),

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
                    onPaid: () => ref
                        .read(transactionProvider(customerId).notifier)
                        .markPaid(d['_id'] as String),
                    onDelete: () => ref
                        .read(transactionProvider(customerId).notifier)
                        .deleteDebt(d['_id'] as String),
                  )),
              const SizedBox(height: 16),
            ],

            // ── Credits ─────────────────────────────────────
            if (txState.credits.isNotEmpty) ...[
              _SectionHeader(
                label: 'Credits Received',
                color: AppTheme.primaryGreen,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(height: 8),
              ...txState.credits.map((c) => _CreditTile(
                    credit: c,
                    onDelete: () => ref
                        .read(transactionProvider(customerId).notifier)
                        .deleteCredit(c['_id'] as String),
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
                        .read(transactionProvider(customerId).notifier)
                        .deleteDebt(d['_id'] as String),
                  )),
            ],

            if (!txState.loading &&
                txState.debts.isEmpty &&
                txState.credits.isEmpty)
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'credit_fab',
              onPressed: () async {
                await context.push('/customer/$customerId/add-credit');
                ref.read(transactionProvider(customerId).notifier).fetchAll();
              },
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
              onPressed: () async {
                await context.push('/customer/$customerId/add-debt');
                ref.read(transactionProvider(customerId).notifier).fetchAll();
              },
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

// ── Widgets ────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
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
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SectionHeader(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ]);
}

class _DebtTile extends StatelessWidget {
  final Map<String, dynamic> debt;
  final VoidCallback? onPaid;
  final VoidCallback onDelete;
  final bool isPaid;
  const _DebtTile(
      {required this.debt,
      this.onPaid,
      required this.onDelete,
      this.isPaid = false});

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.tryParse(debt['date'] as String? ?? '') ?? DateTime.now();
    final amount = (debt['amount'] as num).toDouble();
    final description = debt['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(children: [
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
              Text(description,
                  style: TextStyle(
                    color: isPaid ? AppTheme.textHint : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    decoration: isPaid ? TextDecoration.lineThrough : null,
                  )),
              const SizedBox(height: 2),
              Text(DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
            ],
          ),
        ),
        Text('₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isPaid ? AppTheme.textHint : AppTheme.dangerColor)),
        if (!isPaid && onPaid != null)
          IconButton(
            icon:
                Icon(Icons.delete_outline, color: AppTheme.textHint, size: 20),
            onPressed: onDelete,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
      ]),
    );
  }
}

class _CreditTile extends StatelessWidget {
  final Map<String, dynamic> credit;
  final VoidCallback onDelete;
  const _CreditTile({required this.credit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.tryParse(credit['date'] as String? ?? '') ?? DateTime.now();
    final amount = (credit['amount'] as num).toDouble();
    final description = credit['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: AppTheme.primaryGreen),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
            ],
          ),
        ),
        Text('₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.primaryGreen)),
        IconButton(
          icon: Icon(Icons.delete_outline, color: AppTheme.textHint, size: 20),
          onPressed: onDelete,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}
