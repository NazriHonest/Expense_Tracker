import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../services/api_service.dart';

class GoalProvider with ChangeNotifier {
  // Using the singleton instance automatically
  final ApiService _api = ApiService();

  List<SavingsGoal> _goals = [];
  bool _isLoading = false;

  List<SavingsGoal> get goals => [..._goals];
  bool get isLoading => _isLoading;

  // --- Fetch Goals ---
  Future<void> fetchGoals() async {
    // Prevent multiple simultaneous fetch calls
    if (_isLoading) return;

    _isLoading = true;
    // We don't notifyListeners() here to avoid potential build-phase errors,
    // but you can if your UI handles the loading state explicitly.

    try {
      // The Dio interceptor handles the token automatically
      _goals = await _api.getGoals();
      debugPrint("Goals Fetched: ${_goals.length}");
    } catch (e) {
      debugPrint("Fetch Goals Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Add a Goal ---
  Future<void> addGoal(SavingsGoal goal) async {
    try {
      final newGoal = await _api.createGoal(goal);
      _goals.add(newGoal);
      notifyListeners();
    } catch (e) {
      debugPrint("Add Goal Error: $e");
      rethrow;
    }
  }

  // --- Contribute to a Goal ---
  Future<void> contributeToGoal(String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final originalGoal = _goals[index];

    // 1. Optimistic Update (UI changes immediately)
    _goals[index] = originalGoal.copyWith(
      currentAmount: originalGoal.currentAmount + amount,
    );
    notifyListeners();

    try {
      // 2. Server Sync
      final updatedGoal = await _api.contributeToGoal(goalId, amount);

      // 3. Update with real server data (ensures accurate calculation)
      _goals[index] = updatedGoal;
      notifyListeners();
    } catch (e) {
      // 4. Rollback on failure
      debugPrint("Contribution failed, rolling back: $e");
      _goals[index] = originalGoal;
      notifyListeners();
      rethrow;
    }
  }

  // --- Delete a Goal ---
  Future<void> deleteGoal(String goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final backupGoal = _goals[index];

    // 1. Optimistic Delete
    _goals.removeAt(index);
    notifyListeners();

    try {
      await _api.deleteGoal(goalId);
    } catch (e) {
      // 2. Rollback if server fails
      _goals.insert(index, backupGoal);
      notifyListeners();
      debugPrint("Delete Goal Error: $e");
      rethrow;
    }
  }

  /// Clears local state on logout
  void clearData() {
    _goals = [];
    notifyListeners();
  }
}
