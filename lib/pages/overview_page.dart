import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_finances_wrapped/Transactions/DataAnalysis.dart';
import 'package:flutter_finances_wrapped/app_theme.dart';

class OverviewPage extends StatefulWidget {
  final DataAnalysis? dataAnalysis;

  const OverviewPage({super.key, required this.dataAnalysis});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // empty state — no CSV uploaded yet
    if (widget.dataAnalysis == null || widget.dataAnalysis!.categories.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.softMint,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 48,
                    color: AppTheme.forestGreen.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text(
                  'Upload a CSV on the Home tab to see your overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mutedGreen, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dataAnalysis = widget.dataAnalysis!;
    final totalSpending = dataAnalysis.getTotalSpending();
    final totalTransactions = dataAnalysis.getTotalTransactionCount();

    return Scaffold(
      backgroundColor: AppTheme.softMint,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Financial Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGreen,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── TOP STAT CARDS ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL SPENDING',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: AppTheme.mint.withValues(alpha: 0.5),
                            )),
                        const SizedBox(height: 4),
                        Text(
                          '\$${totalSpending.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRANSACTIONS',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: AppTheme.mint.withValues(alpha: 0.5),
                            )),
                        const SizedBox(height: 4),
                        Text(
                          '$totalTransactions',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── PIE CHART TITLE ─────────────────────────
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 12),

            // ── PIE CHART ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.mintBorder.withValues(alpha: 0.5)),
              ),
              child: SizedBox(
                height: 280,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback:
                          (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: showingSections(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── CATEGORIES LABEL ────────────────────────
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 8),

            // ── CATEGORY LEGEND CARDS ───────────────────
            ...dataAnalysis.categories.entries.map((entry) {
              final category = entry.value;
              final percentage = totalSpending > 0
                  ? (category.totalSpending / totalSpending * 100)
                  : 0;
              final colorIndex =
                  dataAnalysis.categories.keys.toList().indexOf(entry.key);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.mintBorder.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(colorIndex),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${category.totalSpending.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.mutedGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

/*
            // ── BOTTOM INSIGHT CARDS ────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOP VENDOR',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: AppTheme.mint.withValues(alpha: 0.5),
                            )),
                        const SizedBox(height: 4),
                        Text(
                          dataAnalysis.getMostFrequentVendor() ?? '--',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MOST ACTIVE DAY',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: AppTheme.mint.withValues(alpha: 0.5),
                            )),
                        const SizedBox(height: 4),
                        Text(
                          dataAnalysis.getMostActiveDayOfWeek() ?? '--',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            */
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final dataAnalysis = widget.dataAnalysis!;
    final categories = dataAnalysis.categories.values.toList();
    final totalSpending = dataAnalysis.getTotalSpending();

    return List.generate(categories.length, (i) {
      final category = categories[i];
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 110.0 : 100.0;
      final percentage = category.totalSpending / totalSpending * 100;

      return PieChartSectionData(
        color: _getCategoryColor(i),
        value: category.totalSpending,
        title: percentage >= 5.0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getCategoryColor(int index) {
    const colors = [
      Color(0xFF0d3d27), // dark green
      Color(0xFF1a6b52), // forest green
      Color(0xFFe8a946), // amber/gold
      Color(0xFF5b8fd9), // soft blue
      Color(0xFF4ecca3), // mint
      Color(0xFFd4698a), // dusty pink
      Color(0xFF7b6bd4), // soft purple
      Color(0xFF45a5a5), // teal
      Color(0xFFe07b4f), // warm coral
      Color(0xFF6bbd6b), // light green
    ];
    return colors[index % colors.length];
  }
}