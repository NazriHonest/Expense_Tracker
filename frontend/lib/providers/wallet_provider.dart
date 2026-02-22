import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Wallet> _wallets = [];
  bool _isLoading = false;
  String? _error;

  WalletProvider(this._apiService);

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWallets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallets = await _apiService.getWallets();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createWallet(Wallet wallet) async {
    try {
      final newWallet = await _apiService.createWallet(wallet);
      _wallets.add(newWallet);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  Future<void> updateWallet(int id, Wallet wallet) async {
    try {
      final updatedWallet = await _apiService.updateWallet(id, wallet);
      final index = _wallets.indexWhere((w) => w.id == id);
      if (index != -1) {
        _wallets[index] = updatedWallet;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update wallet: $e');
    }
  }

  Future<void> deleteWallet(int id) async {
    try {
      await _apiService.deleteWallet(id);
      _wallets.removeWhere((w) => w.id == id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete wallet: $e');
    }
  }
}
