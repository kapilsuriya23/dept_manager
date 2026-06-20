import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).compute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () =>
                ref.read(analyticsProvider.notifier).compute(),
          ),
        ],
      ),
      body: state.loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  const SizedBox(height: 16),
                  Text('Crunching numbers...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primaryGreen,
              onRefresh: () => ref.read(analyticsProvider.notifier).compute(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(state.error!,
                          style: TextStyle(
                              color: AppTheme.dangerColor, fontSize: 13)),
                    ),

                  // ── Stat cards row ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Collected this month',
                          value:
                              '₹${state.totalCollectedThisMonth.toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                          color: AppTheme.primaryGreen,
                          trend: state.collectionGrowthPercent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Cleared this week',
                          value: '${state.clearedThisWeek}',
                          icon: Icons.check_circle_outline,
                          color: AppTheme.darkGreen,
                          subtitle: 'debts settled',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Monthly trend chart ────────────────────
                  Text('Debt vs Credit',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Last 6 months',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: state.monthlyTrend.isEmpty
                        ? Center(
                            child: Text('No data yet',
                                style: TextStyle(
                                    color: AppTheme.textHint,
                                    fontSize: 13)),
                          )
                        : _TrendChart(data: state.monthlyTrend),
                  ),
                  const SizedBox(height: 8),

                  // ── Legend ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: AppTheme.dangerColor, label: 'Debt'),
                      const SizedBox(width: 20),
                      _LegendDot(
                          color: AppTheme.primaryGreen, label: 'Credit'),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Top customers ───────────────────────────
                  Row(
                    children: [
                      Icon(Icons.leaderboard,
                          color: AppTheme.dangerColor, size: 18),
                      const SizedBox(width: 6),
                      Text('Top Outstanding Customers',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.topCustomers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Center(
                        child: Text('All customers are settled up',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13)),
                      ),
                    )
                  else
                    ...List.generate(state.topCustomers.length, (i) {
                      final c = state.topCustomers[i];
                      final maxBalance =
                          (state.topCustomers.first['netBalance'] as num)
                              .toDouble();
                      final balance =
                          (c['netBalance'] as num).toDouble();
                      return _RankedCustomerTile(
                        rank: i + 1,
                        name: c['name'] as String? ?? '',
                        phone: c['phone'] as String? ?? '',
                        balance: balance,
                        progress: maxBalance > 0 ? balance / maxBalance : 0,
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  trend! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: trend! >= 0
                      ? AppTheme.primaryGreen
                      : AppTheme.dangerColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${trend!.abs().toStringAsFixed(0)}% vs last month',
                  style: TextStyle(
                    color: trend! >= 0
                        ? AppTheme.primaryGreen
                        : AppTheme.dangerColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

// ── Bar chart ──────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final List<MonthlyPoint> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(
      0,
      (max, p) => [max, p.debt, p.credit].reduce((a, b) => a > b ? a : b),
    );
    final chartMax = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        maxY: chartMax,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[idx].label,
                    style: TextStyle(
                        color: AppTheme.textHint, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].debt,
                color: AppTheme.dangerColor,
                width: 8,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: data[i].credit,
                color: AppTheme.primaryGreen,
                width: 8,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
            barsSpace: 4,
          );
        }),
      ),
    );
  }
}

// ── Legend dot ─────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      );
}

// ── Ranked customer tile ───────────────────────────────────
class _RankedCustomerTile extends StatelessWidget {
  final int rank;
  final String name;
  final String phone;
  final double balance;
  final double progress;

  const _RankedCustomerTile({
    required this.rank,
    required this.name,
    required this.phone,
    required this.balance,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? AppTheme.dangerColor
        : rank == 2
            ? const Color(0xFFE08A2E)
            : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$rank',
                style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
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
                        fontSize: 13)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation(
                        AppTheme.dangerColor.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('₹${balance.toStringAsFixed(0)}',
              style: TextStyle(
                  color: AppTheme.dangerColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}