import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:flutter/material.dart';

class BudgetProvider with ChangeNotifier {
  // Using the singleton instance
  final ApiService _apiService = ApiService();

  List<BudgetStatus> _budgets = [];
  bool _isLoading = false;

  List<BudgetStatus> get budgets => [..._budgets];
  bool get isLoading => _isLoading;

  // --- Fetch Budgets ---
  Future<void> fetchAndSetBudgets({int? month, int? year}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ApiService now returns List<dynamic> from Dio response.data
      final List<dynamic> data = await _apiService.getBudgetStatus(
        month: month,
        year: year,
      );

      _budgets = data.map((item) => BudgetStatus.fromJson(item)).toList();
    } catch (error) {
      debugPrint("Error fetching budgets: $error");
      // You could set an error string here to show a specific UI message
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Create / Update Budget ---
  Future<void> addOrUpdateBudget(String category, double amount) async {
    final now = DateTime.now();
    try {
      // Interceptor handles the token automatically
      await _apiService.setBudget(category, amount, now.month, now.year);

      // We refresh the whole list because a budget update usually
      // changes the 'remaining' and 'percentage' fields calculated by the backend
      await fetchAndSetBudgets(month: now.month, year: now.year);
    } catch (error) {
      debugPrint("Error setting budget: $error");
      rethrow;
    }
  }

  // --- Delete Budget ---
  Future<void> deleteBudget(int id) async {
    // We store a backup for "Optimistic UI" rollback if needed
    final existingIndex = _budgets.indexWhere((budget) => budget.id == id);
    if (existingIndex == -1) return;

    final existingBudget = _budgets[existingIndex];

    // Remove locally first for instant feedback
    _budgets.removeAt(existingIndex);
    notifyListeners();

    try {
      await _apiService.deleteBudget(id);
    } catch (error) {
      // Rollback if the server request fails
      _budgets.insert(existingIndex, existingBudget);
      notifyListeners();
      debugPrint("Error deleting budget: $error");
      rethrow;
    }
  }

  // --- Helper: Get budget for a specific category ---
  BudgetStatus? getBudgetByCategory(String category) {
    if (_budgets.isEmpty) return null;

    // Using cast to handle the potential absence of the category gracefully
    final results = _budgets.where(
      (b) => b.category.toLowerCase() == category.toLowerCase(),
    );
    return results.isNotEmpty ? results.first : null;
  }
}
