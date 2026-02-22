import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/api_service.dart';

class DebtProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Debt> _debts = [];
  bool _isLoading = false;
  String? _error;

  DebtProvider(this._apiService);

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalOwedByMe {
    return _debts
        .where((d) => d.isOwedByMe && d.status != 'paid')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalOwedToMe {
    return _debts
        .where((d) => !d.isOwedByMe && d.status != 'paid')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> fetchDebts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _debts = await _apiService.getDebts();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createDebt(Debt debt) async {
    try {
      final newDebt = await _apiService.createDebt(debt);
      _debts.add(newDebt);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create debt: $e');
    }
  }

  Future<void> updateDebt(int id, Debt debt) async {
    try {
      final updatedDebt = await _apiService.updateDebt(id, debt);
      final index = _debts.indexWhere((d) => d.id == id);
      if (index != -1) {
        _debts[index] = updatedDebt;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update debt: $e');
    }
  }

  Future<void> deleteDebt(int id) async {
    try {
      await _apiService.deleteDebt(id);
      _debts.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete debt: $e');
    }
  }
}
