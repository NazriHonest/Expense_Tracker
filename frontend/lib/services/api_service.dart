import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/health.dart';
import '../models/savings_goal.dart';
import '../models/subscription.dart';
import '../models/wallet.dart';
import '../models/debt.dart';
import '../providers/auth_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  static AuthProvider? _authProvider;

  static const String baseUrl = 'https://finance-tracker-app-0qmt.onrender.com';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authProvider?.token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            debugPrint("Unauthorized - Logging out user...");
            _authProvider?.logout();
          }
          return handler.next(e);
        },
      ),
    );
  }

  static void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // --- Auth Endpoints ---
  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/token',
        data: FormData.fromMap({
          'username': email,
          'password': password,
        }),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      return response.data['access_token'];
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['detail'] ??
                          e.response?.data?.toString() ??
                          'Login failed';
      debugPrint('ApiService: Login error - $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('ApiService: Unknown error during login: $e');
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password},
    );
  }

  Future<String?> getUsername() async {
    return _authProvider?.userEmail;
  }

  // --- Debt Methods ---
  Future<List<Debt>> getDebts() async {
    final response = await _dio.get('/debts/');
    final List<dynamic> data = response.data;
    return data.map((json) => Debt.fromJson(json)).toList();
  }

  Future<Debt> createDebt(Debt debt) async {
    final response = await _dio.post('/debts/', data: debt.toJson());
    return Debt.fromJson(response.data);
  }

  Future<Debt> updateDebt(int id, Debt debt) async {
    final response = await _dio.put('/debts/$id', data: debt.toJson());
    return Debt.fromJson(response.data);
  }

  Future<void> deleteDebt(int id) async {
    await _dio.delete('/debts/$id');
  }

  // --- Wallet Methods ---
  Future<List<Wallet>> getWallets() async {
    final response = await _dio.get('/wallets/');
    final List<dynamic> data = response.data;
    return data.map((json) => Wallet.fromJson(json)).toList();
  }

  Future<Wallet> createWallet(Wallet wallet) async {
    final response = await _dio.post('/wallets/', data: wallet.toJson());
    return Wallet.fromJson(response.data);
  }

  Future<Wallet> updateWallet(int id, Wallet wallet) async {
    final response = await _dio.put('/wallets/$id', data: wallet.toJson());
    return Wallet.fromJson(response.data);
  }

  Future<void> deleteWallet(int id) async {
    await _dio.delete('/wallets/$id');
  }

  // --- Expense Endpoints ---
  Future<List<Expense>> getExpenses() async {
    final response = await _dio.get('/expenses/');
    return (response.data as List).map((e) => Expense.fromJson(e)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await _dio.post('/expenses/', data: expense.toJson());
    return Expense.fromJson(response.data);
  }

  Future<void> deleteExpense(int id) async {
    await _dio.delete('/expenses/$id');
  }

  Future<Expense> updateExpense(int id, Expense expense) async {
    final response = await _dio.put('/expenses/$id', data: expense.toJson());
    return Expense.fromJson(response.data);
  }

  Future<List<MonthlySummary>> getMonthlySummary() async {
    final response = await _dio.get('/expenses/summary');
    return (response.data as List)
        .map((e) => MonthlySummary.fromJson(e))
        .toList();
  }

  // --- Income Endpoints ---
  Future<List<dynamic>> getIncomes() async {
    final response = await _dio.get('/income/');
    return response.data;
  }

  Future<dynamic> createIncome(Map<String, dynamic> income) async {
    final response = await _dio.post('/income/', data: income);
    return response.data;
  }

  Future<void> deleteIncome(int id) async {
    await _dio.delete('/income/$id');
  }

  Future<dynamic> updateIncome(int id, Map<String, dynamic> income) async {
    final response = await _dio.put('/income/$id', data: income);
    return response.data;
  }

  Future<Map<String, dynamic>> getBalance() async {
    final response = await _dio.get('/balance');
    return response.data;
  }

  // --- Savings Goal Endpoints ---
  Future<List<SavingsGoal>> getGoals() async {
    final response = await _dio.get('/goals/');
    return (response.data as List).map((e) => SavingsGoal.fromMap(e)).toList();
  }

  Future<SavingsGoal> createGoal(SavingsGoal goal) async {
    final response = await _dio.post('/goals/', data: goal.toMap());
    return SavingsGoal.fromMap(response.data);
  }

  Future<SavingsGoal> contributeToGoal(String id, double amount) async {
    final response = await _dio.patch(
      '/goals/$id/contribute',
      data: {'amount': amount},
    );
    return SavingsGoal.fromMap(response.data);
  }

  Future<void> deleteGoal(String id) async {
    await _dio.delete('/goals/$id');
  }

  // --- Subscription Endpoints ---
  Future<List<Subscription>> getSubscriptions() async {
    final response = await _dio.get('/subscriptions/');
    return (response.data as List)
        .map((e) => Subscription.fromJson(e))
        .toList();
  }

  Future<Subscription> createSubscription(Subscription sub) async {
    final response = await _dio.post('/subscriptions/', data: sub.toJson());
    return Subscription.fromJson(response.data);
  }

  Future<Subscription> updateSubscription(int id, Subscription sub) async {
    final response = await _dio.put('/subscriptions/$id', data: sub.toJson());
    return Subscription.fromJson(response.data);
  }

  Future<void> deleteSubscription(int id) async {
    await _dio.delete('/subscriptions/$id');
  }

  Future<List<Expense>> checkRecurringTransactions() async {
    final response = await _dio.post('/subscriptions/check');
    return (response.data as List).map((e) => Expense.fromJson(e)).toList();
  }

  // --- Budget Endpoints ---
  Future<List<dynamic>> getBudgetStatus({int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    final response = await _dio.get(
      '/budgets/status',
      queryParameters: {'month': m, 'year': y},
    );
    return response.data;
  }

  Future<void> setBudget(
    String category,
    double amount,
    int month,
    int year,
  ) async {
    await _dio.post(
      '/budgets/',
      data: {
        'category': category,
        'amount': amount,
        'month': month,
        'year': year,
      },
    );
  }

  Future<void> deleteBudget(int id) async {
    await _dio.delete('/budgets/$id');
  }

  // --- Analytics Endpoints ---
  Future<List<dynamic>> getCategoryBreakdown() async {
    final response = await _dio.get('/analytics/category-breakdown');
    return response.data;
  }

  Future<List<dynamic>> getMonthlyComparison({int months = 6}) async {
    final response = await _dio.get(
      '/analytics/monthly-comparison',
      queryParameters: {'months': months},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getInsights() async {
    final response = await _dio.get('/analytics/insights');
    return response.data;
  }

  // --- Data Export ---
  Future<Map<String, dynamic>> getExportData() async {
    try {
      final response = await _dio.get('/analytics/export');
      return response.data;
    } catch (e) {
      // Fallback: If the analytics/export endpoint fails (e.g. 500 format error on Render),
      // fallback to fetching expenses and incomes separately since those serializers work.
      debugPrint("Export endpoint failed, using fallback APIs. Error: $e");
      final expensesResponse = await _dio.get('/expenses/');
      final incomeResponse = await _dio.get('/income/');

      return {'expenses': expensesResponse.data, 'income': incomeResponse.data};
    }
  }

  // --- Category Management ---
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _dio.get('/categories/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createCategory(
    String name,
    int iconCode,
    int colorValue,
    String type,
  ) async {
    final response = await _dio.post(
      '/categories/',
      data: {
        'name': name,
        'icon_code': iconCode,
        'color_value': colorValue,
        'type': type,
      },
    );
    return response.data;
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete('/categories/$id');
  }

  // --- Health Endpoints ---
  Future<HealthMetrics?> getHealthMetrics(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _dio.get('/health/metrics/$dateStr');
      if (response.data == null) return null;
      return HealthMetrics.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<HealthMetrics> updateHealthMetrics(HealthMetrics metrics) async {
    final response = await _dio.post('/health/metrics', data: metrics.toJson());
    return HealthMetrics.fromJson(response.data);
  }

  Future<HealthSettings> getHealthSettings() async {
    final response = await _dio.get('/health/settings');
    return HealthSettings.fromJson(response.data);
  }

  Future<HealthSettings> updateHealthSettings(HealthSettings settings) async {
    final response = await _dio.post(
      '/health/settings',
      data: settings.toJson(),
    );
    return HealthSettings.fromJson(response.data);
  }
}
