import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// Services & Providers
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/goal_provider.dart';
import '../services/pdf_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<dynamic> _categoryData = [];
  Map<String, dynamic> _insights = {};
  int _touchedIndex = -1;
  String _selectedTimeRange = 'Month';

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateLocalAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    _calculateLocalAnalytics();
    return Future.value();
  }

  void _calculateLocalAnalytics() {
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final allExpenses = expenseProvider.expenses;

    final now = DateTime.now();
    List<dynamic> filteredExpenses = allExpenses.where((e) {
      if (_selectedTimeRange == 'All') return true;
      if (_selectedTimeRange == 'Year') return e.date.year == now.year;
      if (_selectedTimeRange == 'Month') {
        return e.date.year == now.year && e.date.month == now.month;
      }
      if (_selectedTimeRange == 'Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      }
      return true;
    }).toList();

    final Map<String, double> catTotals = {};
    for (var e in filteredExpenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    _categoryData = catTotals.entries
        .map((e) => {'category': e.key, 'total': e.value})
        .toList();

    if (filteredExpenses.isNotEmpty) {
      var topCatEntry = catTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      double totalSum = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
      int days = 1;
      if (_selectedTimeRange == 'Week') days = 7;
      if (_selectedTimeRange == 'Month') {
        days = DateTime(now.year, now.month + 1, 0).day;
      }
      if (_selectedTimeRange == 'Year') days = 365;

      _insights = {
        'top_category': topCatEntry.key,
        'top_category_amount': topCatEntry.value,
        'average_daily_spending': totalSum / days,
      };
    } else {
      _insights = {};
      _categoryData = [];
    }

    setState(() {});
  }

  // --- HEADER SECTION ---
  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Statistics",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Detailed spending analysis",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                color: colorScheme.primary,
              ),
              onPressed: () {
                final expProv = Provider.of<ExpenseProvider>(
                  context,
                  listen: false,
                );
                final budProv = Provider.of<BudgetProvider>(
                  context,
                  listen: false,
                );
                final goalProv = Provider.of<GoalProvider>(
                  context,
                  listen: false,
                );

                PdfService.generateFinancialReport(
                  expenses: expProv.expenses,
                  totalSpent: expProv.totalSpent,
                  totalSaved: goalProv.goals.fold(
                    0.0,
                    (sum, g) => sum + g.currentAmount,
                  ),
                  budgetLimit: budProv.budgets.fold(
                    0.0,
                    (sum, b) => sum + b.limit,
                  ),
                  budgetSpent: budProv.budgets.fold(
                    0.0,
                    (sum, b) => sum + b.spent,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimeFilter(theme),
      ],
    );
  }

  Widget _buildTimeFilter(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final options = ['Week', 'Month', 'Year', 'All'];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((opt) {
          final isSelected = _selectedTimeRange == opt;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTimeRange = opt);
              _calculateLocalAnalytics();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- REMAINING BUDGET CARD ---
  Widget _buildRemainingBudget(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isLoading) return _buildGenericCardShimmer(theme);

    final budgetProv = Provider.of<BudgetProvider>(context);
    final double totalLimit = budgetProv.budgets.fold(
      0.0,
      (sum, b) => sum + b.limit,
    );
    final double totalSpent = budgetProv.budgets.fold(
      0.0,
      (sum, b) => sum + b.spent,
    );
    final double remaining = totalLimit - totalSpent;
    final double progress = totalLimit > 0
        ? (totalSpent / totalLimit).clamp(0.0, 1.0)
        : 0.0;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;
    final dailyAllowance = remaining > 0 ? remaining / daysRemaining : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Remaining Total Budget",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "\$${remaining.toStringAsFixed(2)}",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: remaining < 0
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (remaining > 0) _buildDailyBadge(theme, dailyAllowance),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining < 0 ? colorScheme.error : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Spent: \$${totalSpent.toStringAsFixed(0)}",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                "Total Limit: \$${totalLimit.toStringAsFixed(0)}",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SAVINGS VS SPENDING ---
  Widget _buildSavingsVsSpending(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isLoading) return _buildGenericCardShimmer(theme);

    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);

    final totalSpent = expenseProvider.totalSpent;
    final totalSaved = goalProvider.goals.fold(
      0.0,
      (sum, item) => sum + item.currentAmount,
    );
    final totalOutflow = totalSpent + totalSaved;

    final spentPercent = totalOutflow > 0
        ? (totalSpent / totalOutflow) * 100
        : 0.0;
    final savedPercent = totalOutflow > 0
        ? (totalSaved / totalOutflow) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            "Savings vs. Spending",
            Icons.compare_arrows_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFlowStat(
                theme,
                "Spent",
                totalSpent,
                colorScheme.error,
                isLeft: true,
              ),
              _buildFlowStat(
                theme,
                "Saved",
                totalSaved,
                Colors.green,
                isLeft: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (spentPercent / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${spentPercent.toStringAsFixed(1)}% Expenses",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                "${savedPercent.toStringAsFixed(1)}% Saved",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SMART INSIGHTS ---
  Widget _buildSmartInsights(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> insightEntries = [];
    if (!_isLoading && _insights.isNotEmpty) {
      if (_insights['top_category'] != null) {
        insightEntries.add({
          'title': 'Top Category',
          'value':
              'You spent most on ${_insights['top_category']} (\$${_insights['top_category_amount'].toStringAsFixed(0)})',
          'icon': Icons.trending_up_rounded,
          'color': Colors.orange,
        });
      }
      if (_insights['average_daily_spending'] != null) {
        insightEntries.add({
          'title': 'Daily Average',
          'value':
              'Spending \$${_insights['average_daily_spending'].toStringAsFixed(2)} / day',
          'icon': Icons.calendar_today_rounded,
          'color': Colors.blue,
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(theme, "Smart Insights", Icons.auto_awesome_outlined),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _isLoading ? 3 : insightEntries.length,
            itemBuilder: (context, index) {
              if (_isLoading) return _buildInsightShimmer(theme);
              final item = insightEntries[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item['color'] as Color,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['value'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- PIE CHART ---
  Widget _buildInteractivePieChart(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isLoading) return _buildChartCardShimmer(theme, isPie: true);

    final isDark = theme.brightness == Brightness.dark;
    final total = _categoryData.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as num).toDouble(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildCardHeader(
            theme,
            "Category Split",
            Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (e, r) {
                          setState(() {
                            _touchedIndex =
                                (r == null || r.touchedSection == null)
                                ? -1
                                : r.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: _categoryData.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final val = (entry.value['total'] as num).toDouble();
                        return PieChartSectionData(
                          color: _getCategoryColor(
                            entry.value['category'],
                            isDark,
                          ),
                          value: val,
                          title: '${((val / total) * 100).toStringAsFixed(0)}%',
                          radius: idx == _touchedIndex ? 55 : 45,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _categoryData.length,
                    itemBuilder: (context, i) =>
                        _buildLegendItem(_categoryData[i], isDark, theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BAR CHART ---
  Widget _buildWeeklyBarChart(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isLoading) return _buildChartCardShimmer(theme, isPie: false);

    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final now = DateTime.now();

    List<double> trendData = [];
    List<String> labels = [];
    double maxVal = 100;

    if (_selectedTimeRange == 'Year') {
      trendData = List.generate(12, (index) {
        final month = index + 1;
        return expenseProvider.expenses
            .where((e) => e.date.year == now.year && e.date.month == month)
            .fold(0.0, (sum, e) => sum + e.amount);
      });
      labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    } else {
      int daysToShow = 7;
      trendData = List.generate(daysToShow, (index) {
        final day = now.subtract(Duration(days: (daysToShow - 1) - index));
        return expenseProvider.expenses
            .where(
              (e) =>
                  e.date.year == day.year &&
                  e.date.month == day.month &&
                  e.date.day == day.day,
            )
            .fold(0.0, (sum, e) => sum + e.amount);
      });

      labels = List.generate(daysToShow, (index) {
        final day = now.subtract(Duration(days: (daysToShow - 1) - index));
        const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return weekdays[day.weekday - 1];
      });
    }

    if (trendData.isNotEmpty) {
      maxVal = trendData.reduce((a, b) => a > b ? a : b);
      maxVal = maxVal < 100 ? 100 : (maxVal * 1.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            _selectedTimeRange == 'Year' ? "Monthly Trend" : "Daily Trend",
            Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxVal,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, m) => Text(
                        '\$${v.toInt()}',
                        style: TextStyle(
                          fontSize: 8,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        if (v.toInt() >= 0 && v.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[v.toInt()],
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: trendData
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: colorScheme.primary,
                            width: _selectedTimeRange == 'Year' ? 8 : 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TOP CATEGORIES LIST ---
  Widget _buildTopCategories(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isLoading) return _buildGenericCardShimmer(theme, height: 200);

    final isDark = theme.brightness == Brightness.dark;
    final sortedData = List.from(_categoryData)
      ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));
    final double maxTotal = sortedData.isEmpty
        ? 1.0
        : (sortedData.first['total'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            "Spending by Category",
            Icons.list_alt_rounded,
          ),
          const SizedBox(height: 24),
          ...sortedData.take(5).map((item) {
            return _buildCategoryProgressRow(
              item,
              (item['total'] as num).toDouble(),
              maxTotal,
              _getCategoryColor(item['category'], isDark),
              theme,
            );
          }),
        ],
      ),
    );
  }

  // --- SHIMMER HELPERS ---
  Widget _buildGenericCardShimmer(ThemeData theme, {double height = 160}) {
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.onSurface.withValues(alpha: 0.05),
      highlightColor: colorScheme.onSurface.withValues(alpha: 0.15),
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildInsightShimmer(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.onSurface.withValues(alpha: 0.05),
      highlightColor: colorScheme.onSurface.withValues(alpha: 0.15),
      child: Container(
        width: 280,
        height: 110,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildChartCardShimmer(ThemeData theme, {required bool isPie}) {
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.onSurface.withValues(alpha: 0.05),
      highlightColor: colorScheme.onSurface.withValues(alpha: 0.15),
      child: Container(
        height: isPie ? 320 : 280,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 100,
                  height: 15,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                const Spacer(),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isPie)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  7,
                  (i) => Container(
                    width: 15,
                    height: 40 + (i * 10),
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildCardHeader(ThemeData theme, String title, IconData icon) {
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Icon(icon, color: colorScheme.primary),
      ],
    );
  }

  Widget _buildDailyBadge(ThemeData theme, double amount) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "\$${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
              fontSize: 13,
            ),
          ),
          Text(
            "left / day",
            style: TextStyle(
              fontSize: 8,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStat(
    ThemeData theme,
    String label,
    double amount,
    Color color, {
    required bool isLeft,
  }) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: isLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          "\$${amount.toStringAsFixed(0)}",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(dynamic item, bool isDark, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getCategoryColor(item['category'], isDark),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item['category'],
              style: TextStyle(fontSize: 10, color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressRow(
    dynamic item,
    double amount,
    double maxTotal,
    Color color,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(_getCategoryIcon(item['category']), size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['category'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: amount / maxTotal,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "\$${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category, bool isDark) {
    const Map<String, Color> fixedColors = {
      'Food & Dining': Colors.orange,
      'Transportation': Colors.blue,
      'Shopping': Colors.purple,
      'Entertainment': Colors.pink,
      'Bills & Utilities': Colors.red,
      'Health & Wellness': Colors.teal,
      'Housing': Colors.brown,
      'Education': Colors.indigo,
      'Personal Care': Colors.cyan,
      'Investments': Colors.green,
    };

    if (fixedColors.containsKey(category)) {
      return fixedColors[category]!;
    }

    final int hash = category.codeUnits.fold(
      0,
      (previous, current) => previous + current,
    );
    return Colors.primaries[hash % Colors.primaries.length];
  }

  IconData _getCategoryIcon(String category) {
    if (category == 'Food & Dining') return Icons.restaurant;
    if (category == 'Transportation') return Icons.commute;
    if (category == 'Shopping') return Icons.shopping_bag;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            children: [
              _buildHeader(theme),
              const SizedBox(height: 20),
              _buildRemainingBudget(theme),
              _buildSavingsVsSpending(theme),
              _buildSmartInsights(theme),
              _buildInteractivePieChart(theme),
              _buildTopCategories(theme),
              _buildWeeklyBarChart(theme),
            ],
          ),
        ),
      ),
    );
  }
}
