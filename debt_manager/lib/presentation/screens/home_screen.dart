import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/services/pdf_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(customersProvider.notifier).fetchAll();
    }
  }

  Future<void> _downloadDashboardPdf() async {
    final customerState = ref.read(customersProvider);
    final user = ref.read(authProvider).user;
    final shopName = user?.shopName ?? 'DebtBook';

    if (customerState.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No customers to generate report'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final pdfBytes = await PdfService.generateDashboardReport(
        shopName: shopName,
        customers: customerState.customers,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name:
            'dashboard_report_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customersProvider);
    final total = ref.watch(totalOutstandingProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.shopName ?? 'DebtBook',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (customerState.loading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
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
            tooltip: 'Download Report',
            onPressed: customerState.loading ? null : _downloadDashboardPdf,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
            color: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.borderColor),
            ),
            onSelected: (value) async {
              if (value == 'privacy') {
                context.push('/privacy-policy');
              } else if (value == 'analytics') {
                context.push('/analytics');
              } else if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'privacy',
                child: Row(children: [
                  Icon(Icons.shield_outlined,
                      color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 10),
                  Text('Privacy Policy',
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'analytics',
                child: Row(children: [
                  Icon(Icons.bar_chart_rounded,
                      color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 10),
                  Text('Analytics',
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, color: AppTheme.dangerColor, size: 18),
                  const SizedBox(width: 10),
                  Text('Logout',
                      style:
                          TextStyle(color: AppTheme.dangerColor, fontSize: 14)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () => ref.read(customersProvider.notifier).fetchAll(),
        child: Column(
          children: [
            // ── Banner ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Outstanding',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text('${customerState.customers.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          const Text('customers',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Error ────────────────────────────────────────
            if (customerState.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.dangerColor.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline,
                        color: AppTheme.dangerColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(customerState.error!,
                          style: TextStyle(
                              color: AppTheme.dangerColor, fontSize: 13)),
                    ),
                  ]),
                ),
              ),

            // ── Label ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Customers',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text('Pull to refresh',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────
            Expanded(
              child: customerState.loading && customerState.customers.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen))
                  : customerState.customers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.people_outline,
                                          size: 48,
                                          color: AppTheme.primaryGreen),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('No customers yet',
                                        style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('Tap + to add your first customer',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: customerState.customers.length,
                          itemBuilder: (_, i) {
                            final c = customerState.customers[i];
                            return _CustomerCard(
                              customer: c,
                              onTap: () =>
                                  context.push('/customer/${c['_id']}'),
                              onDelete: () => ref
                                  .read(customersProvider.notifier)
                                  .deleteCustomer(c['_id'] as String),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-customer');
          ref.read(customersProvider.notifier).fetchAll();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Customer',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Delete ${customer['name']} and all their records?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child:
                Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netBalance = (customer['netBalance'] as num?)?.toDouble() ?? 0.0;
    final hasDue = netBalance > 0;
    final name = customer['name'] as String? ?? '';
    final phone = customer['phone'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(phone,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasDue
                        ? AppTheme.dangerColor.withOpacity(0.1)
                        : AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${netBalance.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: hasDue
                            ? AppTheme.dangerColor
                            : AppTheme.successColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Icon(Icons.delete_outline,
                      color: AppTheme.textHint, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
