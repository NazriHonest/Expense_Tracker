import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  // Uses the singleton instance automatically
  final ApiService _apiService = ApiService();

  List<Expense> _expenses = [];
  List<MonthlySummary> _summary = [];
  bool _isLoading = false;

  // Getters
  List<Expense> get expenses => [
    ..._expenses,
  ]; // Return a copy to prevent accidental mutation
  List<MonthlySummary> get summary => [..._summary];
  bool get isLoading => _isLoading;

  /// Total spent calculator based on current local list
  double get totalSpent {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Clears data on logout (called by your MainNavigation or Auth listener)
  void clearData() {
    _expenses = [];
    _summary = [];
    notifyListeners();
  }

  /// Parallel fetch for maximum speed on Render.com
  Future<void> fetchExpenses() async {
    _isLoading = true;
    // We don't notify here to prevent "rebuild during build" errors

    try {
      // Dio interceptor handles the Bearer token automatically
      final results = await Future.wait([
        _apiService.getExpenses(),
        _apiService.getMonthlySummary(),
      ]);

      _expenses = results[0] as List<Expense>;
      _summary = results[1] as List<MonthlySummary>;
    } catch (e) {
      debugPrint("ExpenseProvider Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final newExpense = await _apiService.createExpense(expense);

      // Add to local list immediately
      _expenses.insert(0, newExpense);

      // Refresh summary because a new expense changes the totals/charts
      _summary = await _apiService.getMonthlySummary();

      notifyListeners();
    } catch (e) {
      debugPrint("Add Expense Error: $e");
      rethrow;
    }
  }

  Future<void> updateExpense(int id, Expense expense) async {
    try {
      final updated = await _apiService.updateExpense(id, expense);
      final index = _expenses.indexWhere((e) => e.id == id);

      if (index != -1) {
        _expenses[index] = updated;
        // Refresh summary to reflect changes in charts
        _summary = await _apiService.getMonthlySummary();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Update Expense Error: $e");
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    // --- Optimistic UI Update ---
    final existingIndex = _expenses.indexWhere((e) => e.id == id);
    if (existingIndex == -1) return;

    final existingExpense = _expenses[existingIndex];
    _expenses.removeAt(existingIndex);
    notifyListeners();

    try {
      await _apiService.deleteExpense(id);
      // Optional: update summary if needed, or wait for next fetch
    } catch (e) {
      // Rollback on failure
      _expenses.insert(existingIndex, existingExpense);
      notifyListeners();
      debugPrint("Delete Expense Error: $e");
      rethrow;
    }
  }
}
