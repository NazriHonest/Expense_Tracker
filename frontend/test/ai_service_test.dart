import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/ai_service.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('AIService Tests', () {
    final aiService = AIService();

    group('categorizeExpense', () {
      test('should categorize food-related expenses', () {
        expect(aiService.categorizeExpense('Starbucks coffee', null), 'Food');
        expect(aiService.categorizeExpense('McDonald lunch', null), 'Food');
        expect(aiService.categorizeExpense('Pizza dinner', null), 'Food');
      });

      test('should categorize transport-related expenses', () {
        expect(aiService.categorizeExpense('Uber ride', null), 'Transport');
        expect(aiService.categorizeExpense('Gas station', null), 'Transport');
        expect(aiService.categorizeExpense('Metro ticket', null), 'Transport');
      });

      test('should categorize entertainment expenses', () {
        expect(aiService.categorizeExpense('Netflix subscription', null), 'Entertainment');
        expect(aiService.categorizeExpense('Movie tickets', null), 'Entertainment');
        expect(aiService.categorizeExpense('Spotify premium', null), 'Entertainment');
      });

      test('should keep existing category if not Other', () {
        expect(aiService.categorizeExpense('Random store', 'Shopping'), 'Shopping');
        expect(aiService.categorizeExpense('Some place', 'Bills'), 'Bills');
      });

      test('should return Other for unrecognized titles', () {
        expect(aiService.categorizeExpense('XYZ123 purchase', null), 'Other');
        expect(aiService.categorizeExpense('Unknown transaction', 'Other'), 'Other');
      });
    });

    group('predictNextMonthSpending', () {
      test('should return empty map for no expenses', () {
        expect(aiService.predictNextMonthSpending([]), isEmpty);
      });

      test('should generate predictions for expenses', () {
        final now = DateTime.now();
        final expenses = [
          Expense(
            id: 1,
            title: 'Test',
            amount: 100,
            category: 'Food',
            date: DateTime(now.year, now.month - 1, 15),
          ),
          Expense(
            id: 2,
            title: 'Test2',
            amount: 150,
            category: 'Food',
            date: DateTime(now.year, now.month - 2, 15),
          ),
        ];

        final predictions = aiService.predictNextMonthSpending(expenses);
        expect(predictions.containsKey('Food'), isTrue);
        expect(predictions['Food'], greaterThan(0));
      });
    });

    group('detectAnomalies', () {
      test('should return empty list for insufficient data', () {
        final expenses = List.generate(5, (i) => Expense(
          id: i,
          title: 'Test',
          amount: 50,
          category: 'Food',
          date: DateTime.now().subtract(Duration(days: i)),
        ));
        
        expect(aiService.detectAnomalies(expenses), isEmpty);
      });

      test('should detect unusually high expenses', () {
        final now = DateTime.now();
        final expenses = List.generate(15, (i) => Expense(
          id: i,
          title: 'Normal expense',
          amount: 50,
          category: 'Food',
          date: DateTime(now.year, now.month, i + 1),
        ));
        
        // Add an anomaly
        expenses.add(Expense(
          id: 999,
          title: 'Huge expense',
          amount: 500, // 10x normal
          category: 'Food',
          date: DateTime(now.year, now.month, 20),
        ));

        final anomalies = aiService.detectAnomalies(expenses);
        expect(anomalies.isNotEmpty, isTrue);
        expect(anomalies.first['expense'].id, equals(999));
      });
    });

    group('generateInsights', () {
      test('should return empty insights for no expenses', () {
        expect(aiService.generateInsights([], []), isEmpty);
      });

      test('should generate trend insights', () {
        final now = DateTime.now();
        final expenses = [
          Expense(
            id: 1,
            title: 'Test',
            amount: 100,
            category: 'Food',
            date: DateTime(now.year, now.month - 1, 15),
          ),
          Expense(
            id: 2,
            title: 'Test2',
            amount: 200,
            category: 'Food',
            date: DateTime(now.year, now.month, 15),
          ),
        ];

        final insights = aiService.generateInsights(expenses, [100, 200]);
        expect(insights.containsKey('trend'), isTrue);
        expect(insights.containsKey('trendMessage'), isTrue);
      });
    });

    group('suggestBudgetLimits', () {
      test('should return empty map for no expenses', () {
        expect(aiService.suggestBudgetLimits([]), isEmpty);
      });

      test('should suggest budget limits based on history', () {
        final now = DateTime.now();
        final expenses = [
          Expense(
            id: 1,
            title: 'Test',
            amount: 300,
            category: 'Food',
            date: DateTime(now.year, now.month - 1, 15),
          ),
          Expense(
            id: 2,
            title: 'Test2',
            amount: 300,
            category: 'Food',
            date: DateTime(now.year, now.month - 2, 15),
          ),
          Expense(
            id: 3,
            title: 'Test3',
            amount: 300,
            category: 'Food',
            date: DateTime(now.year, now.month - 3, 15),
          ),
        ];

        final suggestions = aiService.suggestBudgetLimits(expenses);
        expect(suggestions.containsKey('Food'), isTrue);
        // Should suggest 10% reduction from $300/month average = $270
        expect(suggestions['Food'], closeTo(270, 1));
      });
    });
  });
}
