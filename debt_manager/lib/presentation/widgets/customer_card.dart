import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/customer_model.dart';
import '../../providers/debt_provider.dart';

class CustomerCard extends ConsumerWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repositoryProvider);
    final totalOwed = repo.getTotalOutstandingForCustomer(customer.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.accentColor.withOpacity(0.2),
              child: Text(
                customer.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phone,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${totalOwed.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: totalOwed > 0
                        ? AppTheme.dangerColor
                        : AppTheme.successColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white38, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Customer',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete ${customer.name} and all their debts?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );
  }
}
