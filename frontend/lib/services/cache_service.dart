import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/expense.dart';
import '../models/income.dart';

/// Offline-first cache service for data persistence
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;

  /// Initialize connectivity listener
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(results);

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectivityStatus);
    debugPrint('📡 CacheService initialized, online: $_isOnline');
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      debugPrint(
        '📡 Connectivity changed: ${_isOnline ? "Online" : "Offline"}',
      );
      _connectivityController.add(_isOnline);
    }
  }

  // === Expense Cache ===
  Future<void> cacheExpenses(List<Expense> expenses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = expenses.map((e) => e.toJson()).toList();
      await prefs.setString('cache_expenses', jsonEncode(data));
      await prefs.setString(
        'cache_expenses_timestamp',
        DateTime.now().toIso8601String(),
      );
      debugPrint('💾 Cached ${expenses.length} expenses');
    } catch (e) {
      debugPrint('❌ Failed to cache expenses: $e');
    }
  }

  Future<List<Expense>?> getCachedExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('cache_expenses');
      if (data == null) return null;

      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get cached expenses: $e');
      return null;
    }
  }

  // === Income Cache ===
  Future<void> cacheIncomes(List<Income> incomes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = incomes.map((i) => i.toJson()).toList();
      await prefs.setString('cache_incomes', jsonEncode(data));
      debugPrint('💾 Cached ${incomes.length} incomes');
    } catch (e) {
      debugPrint('❌ Failed to cache incomes: $e');
    }
  }

  Future<List<Income>?> getCachedIncomes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('cache_incomes');
      if (data == null) return null;

      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((i) => Income.fromJson(i)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get cached incomes: $e');
      return null;
    }
  }

  // === Generic Cache ===
  Future<void> cacheData<T>(String key, T data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      await prefs.setString(
        '${key}_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Failed to cache $key: $e');
    }
  }

  Future<T?> getCachedData<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      if (data == null) return null;
      return jsonDecode(data) as T;
    } catch (e) {
      debugPrint('❌ Failed to get cached $key: $e');
      return null;
    }
  }

  // === Pending Operations Queue (for offline mode) ===
  Future<void> addPendingOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_operations') ?? [];
      pending.add(
        jsonEncode({
          'operation': operation,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      await prefs.setStringList('pending_operations', pending);
      debugPrint('📝 Added pending operation: $operation');
    } catch (e) {
      debugPrint('❌ Failed to add pending operation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_operations') ?? [];
      return pending
          .map((p) => Map<String, dynamic>.from(jsonDecode(p)))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get pending operations: $e');
      return [];
    }
  }

  Future<void> clearPendingOperation(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_operations') ?? [];
      if (index >= 0 && index < pending.length) {
        pending.removeAt(index);
        await prefs.setStringList('pending_operations', pending);
      }
    } catch (e) {
      debugPrint('❌ Failed to clear pending operation: $e');
    }
  }

  Future<void> clearAllPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_operations');
      debugPrint('🗑️ Cleared all pending operations');
    } catch (e) {
      debugPrint('❌ Failed to clear pending operations: $e');
    }
  }

  // === Cache Age Check ===
  Future<int> getCacheAgeMinutes(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('${key}_timestamp');
      if (timestamp == null) return -1;

      final cacheTime = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(cacheTime).inMinutes;
      return diff;
    } catch (e) {
      return -1;
    }
  }

  /// Check if cache is stale (older than threshold)
  Future<bool> isCacheStale(String key, {int staleMinutes = 30}) async {
    final age = await getCacheAgeMinutes(key);
    return age < 0 || age > staleMinutes;
  }

  // === Clear All Cache ===
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith('cache_'))
          .toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('🗑️ Cleared all cache');
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith('cache_'))
          .toList();

      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }

      return {
        'keys': keys.length,
        'sizeBytes': totalSize,
        'sizeKB': (totalSize / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  // ignore: override_on_non_overriding_member
  void dispose() {
    _connectivityController.close();
  }
}
