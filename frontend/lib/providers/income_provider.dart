import 'package:flutter/material.dart';
import '../models/income.dart';
import '../services/api_service.dart';

class IncomeProvider with ChangeNotifier {
  // Uses the singleton instance from ApiService
  final _apiService = ApiService();

  List<Income> _incomes = [];
  bool _isLoading = false;
  double _totalIncome = 0.0;
  String? _errorMessage;

  // Getters
  List<Income> get incomes => [..._incomes];
  bool get isLoading => _isLoading;
  double get totalIncome => _totalIncome;
  String? get errorMessage => _errorMessage;

  /// Fetch all incomes
  Future<void> fetchIncomes() async {
    _isLoading = true;
    _errorMessage = null;
    // We notify here to show the loading spinner in the UI
    notifyListeners();

    try {
      // ApiService now returns a List<dynamic> via Dio
      final List<dynamic> data = await _apiService.getIncomes();

      _incomes = data.map((json) => Income.fromJson(json)).toList();

      // Sort by date (newest first)
      _incomes.sort((a, b) => b.date.compareTo(a.date));

      _calculateTotal();
    } catch (e) {
      _errorMessage = 'Failed to load incomes. Please try again.';
      debugPrint('Error fetching incomes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new income
  Future<void> addIncome(Income income) async {
    try {
      // The interceptor automatically attaches the Bearer token
      final response = await _apiService.createIncome(income.toJson());

      // Dio handles the JSON decoding, so 'response' is already a Map
      final newIncome = Income.fromJson(response);

      _incomes.insert(0, newIncome);
      _calculateTotal();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding income: $e');
      rethrow;
    }
  }

  /// Update an existing income
  Future<void> updateIncome(int id, Income income) async {
    try {
      // We pass the JSON map to Dio
      final response = await _apiService.updateIncome(id, income.toJson());

      final index = _incomes.indexWhere((element) => element.id == id);
      if (index >= 0) {
        // Use the returned server data to ensure sync (e.g., if server modifies data)
        _incomes[index] = Income.fromJson(response);
        _calculateTotal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating income: $e');
      rethrow;
    }
  }

  /// Delete an income with Optimistic UI
  Future<void> deleteIncome(int id) async {
    final existingIndex = _incomes.indexWhere((item) => item.id == id);
    if (existingIndex == -1) return;

    var tempIncome = _incomes[existingIndex];

    // 1. Remove locally immediately
    _incomes.removeAt(existingIndex);
    _calculateTotal();
    notifyListeners();

    try {
      // 2. Request server deletion
      await _apiService.deleteIncome(id);
    } catch (e) {
      // 3. Rollback if API fails
      _incomes.insert(existingIndex, tempIncome);
      _calculateTotal();
      notifyListeners();
      debugPrint('Error deleting income: $e');
      rethrow;
    }
  }

  void _calculateTotal() {
    _totalIncome = _incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  void clearData() {
    _incomes = [];
    _totalIncome = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
