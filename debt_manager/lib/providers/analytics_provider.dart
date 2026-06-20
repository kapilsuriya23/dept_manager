import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'debt_provider.dart';

class MonthlyPoint {
  final String label; // e.g. "Jan"
  final double debt;
  final double credit;
  MonthlyPoint({required this.label, required this.debt, required this.credit});
}

class AnalyticsState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> topCustomers; // sorted by netBalance desc
  final double totalCollectedThisMonth;
  final double totalCollectedLastMonth;
  final int clearedThisWeek;
  final List<MonthlyPoint> monthlyTrend; // last 6 months

  const AnalyticsState({
    this.loading = false,
    this.error,
    this.topCustomers = const [],
    this.totalCollectedThisMonth = 0,
    this.totalCollectedLastMonth = 0,
    this.clearedThisWeek = 0,
    this.monthlyTrend = const [],
  });

  double get collectionGrowthPercent {
    if (totalCollectedLastMonth == 0) {
      return totalCollectedThisMonth > 0 ? 100 : 0;
    }
    return ((totalCollectedThisMonth - totalCollectedLastMonth) /
            totalCollectedLastMonth) *
        100;
  }

  AnalyticsState copyWith({
    bool? loading,
    String? error,
    List<Map<String, dynamic>>? topCustomers,
    double? totalCollectedThisMonth,
    double? totalCollectedLastMonth,
    int? clearedThisWeek,
    List<MonthlyPoint>? monthlyTrend,
  }) =>
      AnalyticsState(
        loading: loading ?? this.loading,
        error: error,
        topCustomers: topCustomers ?? this.topCustomers,
        totalCollectedThisMonth:
            totalCollectedThisMonth ?? this.totalCollectedThisMonth,
        totalCollectedLastMonth:
            totalCollectedLastMonth ?? this.totalCollectedLastMonth,
        clearedThisWeek: clearedThisWeek ?? this.clearedThisWeek,
        monthlyTrend: monthlyTrend ?? this.monthlyTrend,
      );
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;
  AnalyticsNotifier(this._ref) : super(const AnalyticsState());

  Future<void> compute() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final customerState = _ref.read(customersProvider);
      final customers = customerState.customers;

      // Top 5 customers by outstanding balance
      final sorted = [...customers]..sort((a, b) {
          final balA = (a['netBalance'] as num?)?.toDouble() ?? 0;
          final balB = (b['netBalance'] as num?)?.toDouble() ?? 0;
          return balB.compareTo(balA);
        });
      final top5 = sorted.where((c) {
        final bal = (c['netBalance'] as num?)?.toDouble() ?? 0;
        return bal > 0;
      }).take(5).toList();

      // Fetch all debts + credits across all customers for trend analysis
      final debtService = _ref.read(debtServiceProvider);
      final creditService = _ref.read(creditServiceProvider);

      final allDebts = <Map<String, dynamic>>[];
      final allCredits = <Map<String, dynamic>>[];

      for (final c in customers) {
        final id = c['_id'] as String;
        final debts = await debtService.getForCustomer(id);
        final credits = await creditService.getForCustomer(id);
        allDebts.addAll(debts);
        allCredits.addAll(credits);
      }

      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final weekAgo = now.subtract(const Duration(days: 7));

      // Total collected (credits) this month vs last month
      double thisMonth = 0;
      double lastMonth = 0;
      for (final c in allCredits) {
        final date = DateTime.tryParse(c['date'] as String? ?? '');
        if (date == null) continue;
        final amount = (c['amount'] as num).toDouble();
        if (date.isAfter(thisMonthStart) ||
            date.isAtSameMomentAs(thisMonthStart)) {
          thisMonth += amount;
        } else if (date.isAfter(lastMonthStart) &&
            date.isBefore(thisMonthStart)) {
          lastMonth += amount;
        }
      }

      // Cleared debts this week (paidAt within last 7 days)
      int clearedCount = 0;
      for (final d in allDebts) {
        if (d['isPaid'] == true && d['paidAt'] != null) {
          final paidAt = DateTime.tryParse(d['paidAt'] as String);
          if (paidAt != null && paidAt.isAfter(weekAgo)) {
            clearedCount++;
          }
        }
      }

      // Monthly trend — last 6 months
      final monthLabels = <String>[];
      final monthlyDebt = <double>[];
      final monthlyCredit = <double>[];

      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);
        monthLabels.add(_monthName(monthDate.month));

        double debtSum = 0;
        for (final d in allDebts) {
          final date = DateTime.tryParse(d['date'] as String? ?? '');
          if (date == null) continue;
          if (!date.isBefore(monthDate) && date.isBefore(nextMonth)) {
            debtSum += (d['amount'] as num).toDouble();
          }
        }
        monthlyDebt.add(debtSum);

        double creditSum = 0;
        for (final c in allCredits) {
          final date = DateTime.tryParse(c['date'] as String? ?? '');
          if (date == null) continue;
          if (!date.isBefore(monthDate) && date.isBefore(nextMonth)) {
            creditSum += (c['amount'] as num).toDouble();
          }
        }
        monthlyCredit.add(creditSum);
      }

      final trend = List.generate(
        6,
        (i) => MonthlyPoint(
          label: monthLabels[i],
          debt: monthlyDebt[i],
          credit: monthlyCredit[i],
        ),
      );

      state = state.copyWith(
        loading: false,
        topCustomers: top5,
        totalCollectedThisMonth: thisMonth,
        totalCollectedLastMonth: lastMonth,
        clearedThisWeek: clearedCount,
        monthlyTrend: trend,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final idx = ((month - 1) % 12 + 12) % 12;
    return names[idx];
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(ref),
);