import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
  // Use 10.0.2.2 for Android emulators to access the host machine's localhost
  //static const String baseUrl = 'http://10.0.2.2:8000';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30), // Reduced from 120
        receiveTimeout: const Duration(seconds: 30), // Reduced from 120
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Override the HTTP client to bypass SSL certificate errors for debugging
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        print(
          'ApiService: Bad certificate for $host:$port — bypassing for debug',
        );
        return true;
      };
      return client;
    };

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (o) => print('[DIO] $o'),
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
        onError: (DioException e, handler) async {
          print('❌ [DIO] *** DioException ***:');
          print('❌ [DIO] uri: ${e.requestOptions.uri}');
          print('❌ [DIO] type: ${e.type}');
          print('❌ [DIO] message: ${e.message}');
          print('❌ [DIO] error: ${e.error}');

          // Handle 401 Unauthorized
          if (e.response?.statusCode == 401) {
            debugPrint("🔐 Unauthorized - Logging out user...");
            _authProvider?.logout();
            return handler.next(e);
          }

          // Handle connection errors - retry logic for server wake-up
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            // Check if this is the first retry attempt
            final retryCount = e.requestOptions.extra['retryCount'] ?? 0;

            if (retryCount < 3) {
              debugPrint(
                '🔄 [DIO] Connection error, retry ${retryCount + 1}/3 in 2 seconds...',
              );

              // Wait for server to wake up (longer on first retry)
              await Future.delayed(
                retryCount == 0
                    ? const Duration(seconds: 3)
                    : const Duration(seconds: 2),
              );

              try {
                // Clone the request options and increment retry count
                final options = e.requestOptions.copyWith(
                  extra: {
                    ...e.requestOptions.extra,
                    'retryCount': retryCount + 1,
                  },
                );

                // Retry the request
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (retryError) {
                debugPrint('❌ [DIO] Retry failed: $retryError');
                return handler.next(e);
              }
            } else {
              debugPrint(
                '❌ [DIO] Max retries reached for ${e.requestOptions.path}',
              );
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  static void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Helper method to check if server is alive
  Future<bool> checkServerHealth() async {
    try {
      print('🏥 [ApiService] Checking server health...');

      // Use the dedicated health endpoint with HEAD request (lightweight)
      await _dio.head('/health/ping').timeout(const Duration(seconds: 5));
      print('✅ [ApiService] Server is healthy');
      return true;
    } on DioException catch (e) {
      // If HEAD fails, try GET
      try {
        await _dio.get('/health/').timeout(const Duration(seconds: 5));
        print('✅ [ApiService] Server is healthy (via GET)');
        return true;
      } catch (getError) {
        print('❌ [ApiService] GET also failed: $getError');
      }

      // If health endpoint fails, try root as last resort
      try {
        await _dio.get('/').timeout(const Duration(seconds: 5));
        print('✅ [ApiService] Server is healthy (via root)');
        return true;
      } catch (rootError) {
        print('❌ [ApiService] All health checks failed');
        return false;
      }
    } catch (e) {
      print('❌ [ApiService] Server health check failed: $e');
      return false;
    }
  }

  // --- Auth Endpoints ---
  Future<String> login(String email, String password) async {
    try {
      print('🔐 [ApiService] Sending login request for email $email');

      // First, check if server is reachable (optional)
      final isHealthy = await checkServerHealth();
      if (!isHealthy) {
        print(
          '⚠️ [ApiService] Server not responding, but will try login anyway',
        );
      }

      final response = await _dio.post(
        '/auth/token',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      print('✅ [ApiService] Login successful');
      return response.data['access_token'];
    } on DioException catch (e) {
      print('❌ [ApiService] DioException type: ${e.type}');
      print('❌ [ApiService] DioException message: ${e.message}');
      print('❌ [ApiService] DioException error: ${e.error}');
      print(
        '❌ [ApiService] DioException response: ${e.response?.statusCode} - ${e.response?.data}',
      );

      // Create user-friendly error messages
      String errorMessage;

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        errorMessage =
            'Cannot connect to server. The server might be starting up. Please wait 10 seconds and try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Server is taking too long to respond. Please try again.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Invalid email or password';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Login service not found. Please contact support.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.response?.statusCode == 503) {
        errorMessage =
            'Server is currently unavailable. Please try again in a few minutes.';
      } else {
        errorMessage =
            e.response?.data['detail'] ?? 'Login failed: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('❌ [ApiService] Unknown error caught during login: $e');
      throw Exception('Login failed: Unexpected error occurred');
    }
  }

  Future<void> register(String email, String password) async {
    try {
      print('📝 [ApiService] Sending register request for email $email');
      await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      print('✅ [ApiService] Registration successful');
    } on DioException catch (e) {
      print('❌ [ApiService] Registration error: ${e.message}');

      String errorMessage;
      if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Cannot connect to server. Please check your internet connection.';
      } else if (e.response?.statusCode == 400) {
        errorMessage =
            e.response?.data['detail'] ??
            'Registration failed. Email might already be registered.';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }

      throw Exception(errorMessage);
    }
  }

  Future<String?> getUsername() async {
    return _authProvider?.userEmail;
  }

  // --- Debt Methods ---
  Future<List<Debt>> getDebts() async {
    try {
      final response = await _dio.get('/debts/');
      final List<dynamic> data = response.data;
      return data.map((json) => Debt.fromJson(json)).toList();
    } catch (e) {
      print('❌ [ApiService] Error fetching debts: $e');
      rethrow;
    }
  }

  Future<Debt> createDebt(Debt debt) async {
    try {
      final response = await _dio.post('/debts/', data: debt.toJson());
      return Debt.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error creating debt: $e');
      rethrow;
    }
  }

  Future<Debt> updateDebt(int id, Debt debt) async {
    try {
      final response = await _dio.put('/debts/$id', data: debt.toJson());
      return Debt.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error updating debt: $e');
      rethrow;
    }
  }

  Future<void> deleteDebt(int id) async {
    try {
      await _dio.delete('/debts/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting debt: $e');
      rethrow;
    }
  }

  // --- Wallet Methods ---
  Future<List<Wallet>> getWallets() async {
    try {
      final response = await _dio.get('/wallets/');
      final List<dynamic> data = response.data;
      return data.map((json) => Wallet.fromJson(json)).toList();
    } catch (e) {
      print('❌ [ApiService] Error fetching wallets: $e');
      rethrow;
    }
  }

  Future<Wallet> createWallet(Wallet wallet) async {
    try {
      final response = await _dio.post('/wallets/', data: wallet.toJson());
      return Wallet.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error creating wallet: $e');
      rethrow;
    }
  }

  Future<Wallet> updateWallet(int id, Wallet wallet) async {
    try {
      final response = await _dio.put('/wallets/$id', data: wallet.toJson());
      return Wallet.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error updating wallet: $e');
      rethrow;
    }
  }

  Future<void> deleteWallet(int id) async {
    try {
      await _dio.delete('/wallets/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting wallet: $e');
      rethrow;
    }
  }

  // --- Expense Endpoints ---
  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _dio.get('/expenses/');
      return (response.data as List).map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      print('❌ [ApiService] Error fetching expenses: $e');
      rethrow;
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    try {
      final response = await _dio.post('/expenses/', data: expense.toJson());
      return Expense.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error creating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _dio.delete('/expenses/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting expense: $e');
      rethrow;
    }
  }

  Future<Expense> updateExpense(int id, Expense expense) async {
    try {
      final response = await _dio.put('/expenses/$id', data: expense.toJson());
      return Expense.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error updating expense: $e');
      rethrow;
    }
  }

  Future<List<MonthlySummary>> getMonthlySummary() async {
    try {
      final response = await _dio.get('/expenses/summary');
      return (response.data as List)
          .map((e) => MonthlySummary.fromJson(e))
          .toList();
    } catch (e) {
      print('❌ [ApiService] Error fetching monthly summary: $e');
      rethrow;
    }
  }

  // --- Income Endpoints ---
  Future<List<dynamic>> getIncomes() async {
    try {
      final response = await _dio.get('/income/');
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error fetching incomes: $e');
      rethrow;
    }
  }

  Future<dynamic> createIncome(Map<String, dynamic> income) async {
    try {
      final response = await _dio.post('/income/', data: income);
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error creating income: $e');
      rethrow;
    }
  }

  Future<void> deleteIncome(int id) async {
    try {
      await _dio.delete('/income/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting income: $e');
      rethrow;
    }
  }

  Future<dynamic> updateIncome(int id, Map<String, dynamic> income) async {
    try {
      final response = await _dio.put('/income/$id', data: income);
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error updating income: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _dio.get('/balance');
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error fetching balance: $e');
      rethrow;
    }
  }

  // --- Savings Goal Endpoints ---
  Future<List<SavingsGoal>> getGoals() async {
    try {
      final response = await _dio.get('/goals/');
      return (response.data as List)
          .map((e) => SavingsGoal.fromMap(e))
          .toList();
    } catch (e) {
      print('❌ [ApiService] Error fetching goals: $e');
      rethrow;
    }
  }

  Future<SavingsGoal> createGoal(SavingsGoal goal) async {
    try {
      final response = await _dio.post('/goals/', data: goal.toMap());
      return SavingsGoal.fromMap(response.data);
    } catch (e) {
      print('❌ [ApiService] Error creating goal: $e');
      rethrow;
    }
  }

  Future<SavingsGoal> contributeToGoal(String id, double amount) async {
    try {
      final response = await _dio.patch(
        '/goals/$id/contribute',
        data: {'amount': amount},
      );
      return SavingsGoal.fromMap(response.data);
    } catch (e) {
      print('❌ [ApiService] Error contributing to goal: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _dio.delete('/goals/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting goal: $e');
      rethrow;
    }
  }

  // --- Subscription Endpoints ---
  Future<List<Subscription>> getSubscriptions() async {
    try {
      final response = await _dio.get('/subscriptions/');
      return (response.data as List)
          .map((e) => Subscription.fromJson(e))
          .toList();
    } catch (e) {
      print('❌ [ApiService] Error fetching subscriptions: $e');
      rethrow;
    }
  }

  Future<Subscription> createSubscription(Subscription sub) async {
    try {
      final response = await _dio.post('/subscriptions/', data: sub.toJson());
      return Subscription.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error creating subscription: $e');
      rethrow;
    }
  }

  Future<Subscription> updateSubscription(int id, Subscription sub) async {
    try {
      final response = await _dio.put('/subscriptions/$id', data: sub.toJson());
      return Subscription.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error updating subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(int id) async {
    try {
      await _dio.delete('/subscriptions/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting subscription: $e');
      rethrow;
    }
  }

  Future<List<Expense>> checkRecurringTransactions() async {
    try {
      final response = await _dio.post('/subscriptions/check');
      return (response.data as List).map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      print('❌ [ApiService] Error checking recurring transactions: $e');
      rethrow;
    }
  }

  // --- Budget Endpoints ---
  Future<List<dynamic>> getBudgetStatus({int? month, int? year}) async {
    try {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final response = await _dio.get(
        '/budgets/status',
        queryParameters: {'month': m, 'year': y},
      );
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error fetching budget status: $e');
      rethrow;
    }
  }

  Future<void> setBudget(
    String category,
    double amount,
    int month,
    int year,
  ) async {
    try {
      await _dio.post(
        '/budgets/',
        data: {
          'category': category,
          'amount': amount,
          'month': month,
          'year': year,
        },
      );
    } catch (e) {
      print('❌ [ApiService] Error setting budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _dio.delete('/budgets/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting budget: $e');
      rethrow;
    }
  }

  // --- Analytics Endpoints ---
  Future<List<dynamic>> getCategoryBreakdown() async {
    try {
      final response = await _dio.get('/analytics/category-breakdown');
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error fetching category breakdown: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getMonthlyComparison({int months = 6}) async {
    try {
      final response = await _dio.get(
        '/analytics/monthly-comparison',
        queryParameters: {'months': months},
      );
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error fetching monthly comparison: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInsights() async {
    try {
      final response = await _dio.get('/analytics/insights');
      return response.data;
    } catch (e) {
      print('❌ [ApiService] Error fetching insights: $e');
      rethrow;
    }
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
      try {
        final expensesResponse = await _dio.get('/expenses/');
        final incomeResponse = await _dio.get('/income/');
        return {
          'expenses': expensesResponse.data,
          'income': incomeResponse.data,
        };
      } catch (fallbackError) {
        print('❌ [ApiService] Fallback export also failed: $fallbackError');
        rethrow;
      }
    }
  }

  // --- Category Management ---
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get('/categories/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('❌ [ApiService] Error fetching categories: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createCategory(
    String name,
    int iconCode,
    int colorValue,
    String type,
  ) async {
    try {
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
    } catch (e) {
      print('❌ [ApiService] Error creating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete('/categories/$id');
    } catch (e) {
      print('❌ [ApiService] Error deleting category: $e');
      rethrow;
    }
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
      print('❌ [ApiService] Error fetching health metrics: $e');
      rethrow;
    }
  }

  Future<HealthMetrics> updateHealthMetrics(HealthMetrics metrics) async {
    try {
      final response = await _dio.post(
        '/health/metrics',
        data: metrics.toJson(),
      );
      return HealthMetrics.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error updating health metrics: $e');
      rethrow;
    }
  }

  Future<HealthSettings> getHealthSettings() async {
    try {
      final response = await _dio.get('/health/settings');
      return HealthSettings.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error fetching health settings: $e');
      rethrow;
    }
  }

  Future<HealthSettings> updateHealthSettings(HealthSettings settings) async {
    try {
      final response = await _dio.post(
        '/health/settings',
        data: settings.toJson(),
      );
      return HealthSettings.fromJson(response.data);
    } catch (e) {
      print('❌ [ApiService] Error updating health settings: $e');
      rethrow;
    }
  }
}
