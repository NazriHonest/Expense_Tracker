import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../services/ai_service.dart';
import '../services/excel_service.dart';
import '../models/expense.dart';

/// Advanced analytics screen with YoY comparison and AI insights
class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AI Insights
  Map<String, dynamic> _aiInsights = {};
  Map<String, double> _predictions = {};
  List<Map<String, dynamic>> _anomalies = [];

  // Year over Year data
  final Map<int, double> _yearlyTotals = {};
  final Map<int, List<double>> _monthlyTrendsByYear = {};
  int _selectedYear1 = DateTime.now().year - 1;
  int _selectedYear2 = DateTime.now().year;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final expenses = expenseProvider.expenses;

    // Calculate AI insights
    _calculateAIInsights(expenses);

    // Calculate yearly data
    _calculateYearOverYearData(expenses);

    setState(() => _isLoading = false);
  }

  void _calculateAIInsights(List<Expense> expenses) {
    final aiService = AIService();
    _aiInsights = aiService.generateInsights(expenses, []);
    _predictions = aiService.predictNextMonthSpending(expenses);
    _anomalies = aiService.detectAnomalies(expenses);
  }

  void _calculateYearOverYearData(List<Expense> expenses) {
    //final now = DateTime.now();
    _yearlyTotals.clear();
    _monthlyTrendsByYear.clear();

    // Group by year
    for (final expense in expenses) {
      final year = expense.date.year;
      _yearlyTotals[year] = (_yearlyTotals[year] ?? 0) + expense.amount;

      // Monthly breakdown
      _monthlyTrendsByYear.putIfAbsent(year, () => List.filled(12, 0.0));
      _monthlyTrendsByYear[year]![expense.date.month - 1] += expense.amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportToExcel(),
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAiInsightsTab(),
                _buildYearOverYearTab(),
                _buildPredictionsTab(),
              ],
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.psychology), text: 'AI Insights'),
          Tab(icon: Icon(Icons.trending_up), text: 'Year-over-Year'),
          Tab(icon: Icon(Icons.auto_awesome), text: 'Predictions'),
        ],
      ),
    );
  }

  Widget _buildAiInsightsTab() {
    final currencyFormat = NumberFormat.simpleCurrency();

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trend Insight Card
          if (_aiInsights['trend'] != null)
            _buildInsightCard(
              title: 'Spending Trend',
              icon: Icons.trending_up,
              color: _aiInsights['trend'] == 'decreasing'
                  ? Colors.green
                  : _aiInsights['trend'] == 'increasing'
                  ? Colors.red
                  : Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _aiInsights['trendMessage'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Change: ${_aiInsights['trendPercentage']?.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Top Category Card
          if (_aiInsights['topCategory'] != null)
            _buildInsightCard(
              title: 'Top Spending Category',
              icon: Icons.category,
              color: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _aiInsights['topCategory'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(
                      _aiInsights['topCategoryAmount'] ?? 0,
                    ),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Anomalies Card
          if (_anomalies.isNotEmpty)
            _buildInsightCard(
              title: 'Unusual Spending Detected',
              icon: Icons.warning_amber,
              color: Colors.amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found ${_anomalies.length} unusual transaction(s)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._anomalies
                      .take(3)
                      .map(
                        (anomaly) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: anomaly['severity'] == 'high'
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${(anomaly['expense'] as dynamic).title}: ${currencyFormat.format((anomaly['expense'] as dynamic).amount)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Savings Potential Card
          if (_aiInsights['potentialSavings'] != null &&
              _aiInsights['potentialSavings'] > 0)
            _buildInsightCard(
              title: 'Potential Savings',
              icon: Icons.savings,
              color: Colors.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'By reducing unusual expenses, you could save:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(_aiInsights['potentialSavings']),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYearOverYearTab() {
    final years = _yearlyTotals.keys.toList()..sort();

    if (years.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.data_usage, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Need at least 2 years of data',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Year Selection
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compare Years',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedYear1,
                        isExpanded: true,
                        items: years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedYear1 = v!),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'vs',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedYear2,
                        isExpanded: true,
                        items: years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedYear2 = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Yearly Comparison Card
        _buildYearComparisonCard(),

        const SizedBox(height: 16),

        // Monthly Trend Chart
        _buildMonthlyTrendChart(),
      ],
    );
  }

  Widget _buildYearComparisonCard() {
    //final currencyFormat = NumberFormat.simpleCurrency();
    final year1Total = _yearlyTotals[_selectedYear1] ?? 0;
    final year2Total = _yearlyTotals[_selectedYear2] ?? 0;
    final change = year1Total > 0
        ? ((year2Total - year1Total) / year1Total * 100)
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildYearStat(_selectedYear1.toString(), year1Total),
                Column(
                  children: [
                    Icon(
                      change >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: change >= 0 ? Colors.red : Colors.green,
                      size: 32,
                    ),
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: change >= 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                _buildYearStat(_selectedYear2.toString(), year2Total),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearStat(String year, double amount) {
    final currencyFormat = NumberFormat.simpleCurrency();
    return Column(
      children: [
        Text(
          year,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendChart() {
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final data1 = _monthlyTrendsByYear[_selectedYear1] ?? List.filled(12, 0.0);
    final data2 = _monthlyTrendsByYear[_selectedYear2] ?? List.filled(12, 0.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    12,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data1[i],
                          color: Colors.blue.withOpacity(0.7),
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: data2[i],
                          color: Colors.green.withOpacity(0.7),
                          width: 8,
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) => Text(
                          months[v.toInt()],
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.blue, '$_selectedYear1'),
                const SizedBox(width: 24),
                _buildLegend(Colors.green, '$_selectedYear2'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildPredictionsTab() {
    final currencyFormat = NumberFormat.simpleCurrency();

    if (_predictions.isEmpty) {
      return const Center(child: Text('Not enough data for predictions'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Month Predictions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Based on your spending history, here\'s what you might spend next month:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._predictions.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 16)),
                        Text(
                          currencyFormat.format(entry.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      final expenses = expenseProvider.expenses;

      // Group by year
      final yearlyExpenses = <int, List<dynamic>>{};
      for (final expense in expenses) {
        final year = expense.date.year;
        yearlyExpenses.putIfAbsent(year, () => []);
        yearlyExpenses[year]!.add(expense);
      }

      final file = await ExcelService().exportYearOverYearComparison(
        yearlyExpenses.map((k, v) => MapEntry(k, v.cast())).cast(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported to: ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    }
  }
}
