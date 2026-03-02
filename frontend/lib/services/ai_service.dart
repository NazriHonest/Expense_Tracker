import 'dart:math';
import 'package:flutter/material.dart';
import '../models/expense.dart';

/// AI-powered features for expense analysis
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'restaurant',
      'cafe',
      'food',
      'lunch',
      'dinner',
      'breakfast',
      'coffee',
      'pizza',
      'burger',
    ],
    'Transport': [
      'Rikab',
      'taxi',
      'gas',
      'fuel',
      'parking',
      'bus',
      'train',
      'airline',
      'hotel',
    ],
    'Shopping': [
      'amazon',
      'Supermarket',
      'target',
      'mall',
      'store',
      'clothing',
      'shoes',
      'electronics',
    ],
    'Entertainment': [
      'netflix',
      'spotify',
      'cinema',
      'movie',
      'theater',
      'game',
      'concert',
      'music',
    ],
    'Bills': [
      'electric',
      'water',
      'internet',
      'phone',
      'utility',
      'insurance',
      'subscription',
    ],
    'Healthcare': [
      'pharmacy',
      'doctor',
      'hospital',
      'medicine',
      'dental',
      'gym',
      'fitness',
    ],
    'Income': ['salary', 'paycheck', 'deposit', 'transfer', 'refund', 'bonus'],
  };

  /// Smart categorization based on title using keyword matching
  String categorizeExpense(String title, String? currentCategory) {
    // If already categorized and not "Other", keep it
    if (currentCategory != null &&
        currentCategory.isNotEmpty &&
        currentCategory != 'Other') {
      return currentCategory;
    }

    final titleLower = title.toLowerCase();

    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (titleLower.contains(keyword)) {
          debugPrint(
            '🤖 AI: Categorized "$title" as "${entry.key}" (matched: $keyword)',
          );
          return entry.key;
        }
      }
    }

    debugPrint('🤖 AI: No match for "$title", using "Other"');
    return 'Other';
  }

  /// Predict next month's spending based on historical data
  Map<String, double> predictNextMonthSpending(List<Expense> expenses) {
    if (expenses.isEmpty) return {};

    final now = DateTime.now();
    final Map<String, List<double>> categoryHistory = {};

    // Group expenses by category and month (last 6 months)
    for (var i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthExpenses = expenses.where(
        (e) => e.date.year == month.year && e.date.month == month.month,
      );

      for (final expense in monthExpenses) {
        categoryHistory.putIfAbsent(
          expense.category,
          () => List.filled(6, 0.0),
        );
        categoryHistory[expense.category]![5 - i] =
            (categoryHistory[expense.category]![5 - i]) + expense.amount;
      }
    }

    // Predict using simple linear regression
    final predictions = <String, double>{};
    for (final entry in categoryHistory.entries) {
      final trend = _calculateTrend(entry.value);
      final lastMonthValue = entry.value.last;
      predictions[entry.key] = lastMonthValue * (1 + trend);
      debugPrint(
        '🤖 AI: Predicted ${entry.key} spending: \$${predictions[entry.key]!.toStringAsFixed(2)} (trend: ${(trend * 100).toStringAsFixed(1)}%)',
      );
    }

    return predictions;
  }

  /// Detect anomalies in spending patterns
  List<Map<String, dynamic>> detectAnomalies(List<Expense> expenses) {
    if (expenses.length < 10) return []; // Need enough data

    final anomalies = <Map<String, dynamic>>[];
    //final now = DateTime.now();

    // Calculate average and standard deviation per category
    final Map<String, List<double>> categoryAmounts = {};
    for (final expense in expenses) {
      categoryAmounts.putIfAbsent(expense.category, () => []);
      categoryAmounts[expense.category]!.add(expense.amount);
    }

    final Map<String, Map<String, double>> categoryStats = {};
    for (final entry in categoryAmounts.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final variance =
          entry.value.fold<double>(0, (sum, x) => sum + pow(x - avg, 2)) /
          entry.value.length;
      final stdDev = sqrt(variance);

      categoryStats[entry.key] = {'avg': avg, 'stdDev': stdDev};
    }

    // Find anomalies (transactions > 2 standard deviations from mean)
    for (final expense in expenses) {
      final stats = categoryStats[expense.category];
      if (stats == null) continue;

      final zScore = (expense.amount - stats['avg']!) / stats['stdDev']!;
      if (zScore > 2.5) {
        anomalies.add({
          'expense': expense,
          'zScore': zScore,
          'reason': 'Unusually high for ${expense.category}',
          'severity': zScore > 3.5 ? 'high' : 'medium',
        });
        debugPrint(
          '🤖 AI: Anomaly detected - ${expense.title} (\$${expense.amount}) in ${expense.category} (z-score: ${zScore.toStringAsFixed(2)})',
        );
      }
    }

    return anomalies;
  }

  /// Calculate spending trend (-1 to 1)
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;

    final n = values.length;
    final xMean = (n - 1) / 2;
    final yMean = values.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;

    for (var i = 0; i < n; i++) {
      numerator += (i - xMean) * (values[i] - yMean);
      denominator += pow(i - xMean, 2);
    }

    if (denominator == 0) return 0;

    final slope = numerator / denominator;
    return (slope / yMean).clamp(-1.0, 1.0);
  }

  /// Get AI-powered insights
  Map<String, dynamic> generateInsights(
    List<Expense> expenses,
    List<double> monthlyTrend,
  ) {
    final insights = <String, dynamic>{};

    if (expenses.isEmpty) return insights;

    // Trend analysis
    if (monthlyTrend.length >= 2) {
      final lastMonth = monthlyTrend.last;
      final prevMonth = monthlyTrend[monthlyTrend.length - 2];
      final change = ((lastMonth - prevMonth) / prevMonth * 100);

      insights['trend'] = change > 5
          ? 'increasing'
          : change < -5
          ? 'decreasing'
          : 'stable';
      insights['trendPercentage'] = change.abs();
      insights['trendMessage'] = change > 5
          ? 'Spending increased by ${change.toStringAsFixed(1)}% this month'
          : change < -5
          ? 'Great! Spending decreased by ${change.abs().toStringAsFixed(1)}% this month'
          : 'Spending is stable compared to last month';
    }

    // Top spending category
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights['topCategory'] = topCategory.key;
      insights['topCategoryAmount'] = topCategory.value;
    }

    // Savings potential
    //final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final anomalies = detectAnomalies(expenses);
    final potentialSavings = anomalies.fold<double>(
      0,
      (sum, a) => sum + (a['expense'] as Expense).amount * 0.5,
    );

    insights['potentialSavings'] = potentialSavings;
    insights['anomalyCount'] = anomalies.length;

    return insights;
  }

  /// Suggest budget limits based on spending history
  Map<String, double> suggestBudgetLimits(List<Expense> expenses) {
    final now = DateTime.now();
    final recentExpenses = expenses.where((e) {
      final diff = now.difference(e.date).inDays;
      return diff >= 0 && diff <= 90; // Last 3 months
    }).toList();

    final categoryTotals = <String, double>{};
    for (final expense in recentExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // Suggest 10% reduction from average monthly spending
    final suggestions = <String, double>{};
    for (final entry in categoryTotals.entries) {
      final monthlyAvg = entry.value / 3;
      suggestions[entry.key] = monthlyAvg * 0.9; // 10% reduction goal
    }

    return suggestions;
  }
}
