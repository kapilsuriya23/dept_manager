import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';
import '../widgets/customer_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final repo = ref.read(repositoryProvider);
    final total = repo.getTotalOutstanding();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DebtBook',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
            ),
            Text(
              "Dad's Shop",
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Total outstanding banner ─────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Outstanding',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${customers.length} customers',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // ── Customer list ────────────────────────────────
          Expanded(
            child: customers.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customers.length,
                    itemBuilder: (_, i) => CustomerCard(
                      customer: customers[i],
                      onTap: () => context.push('/customer/${customers[i].id}'),
                      onDelete: () => ref
                          .read(customersProvider.notifier)
                          .deleteCustomer(customers[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-customer'),
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label:
            const Text('Add Customer', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No customers yet',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const Text(
            'Tap + to add your first customer',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
