import 'package:flutter/foundation.dart';
import '../models/health.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class HealthProvider with ChangeNotifier {
  HealthMetrics? _todayMetrics;
  HealthSettings? _settings;
  List<HealthMetrics> _weeklyMetrics = [];
  bool _isLoading = false;

  HealthMetrics? get todayMetrics => _todayMetrics;
  HealthSettings? get settings => _settings;
  List<HealthMetrics> get weeklyMetrics => _weeklyMetrics;
  bool get isLoading => _isLoading;

  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  HealthProvider() {
    _notificationService.initialize();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _apiService.getHealthSettings();
      _todayMetrics = await _apiService.getHealthMetrics(DateTime.now());

      if (_todayMetrics == null) {
        _todayMetrics = HealthMetrics(date: DateTime.now());
        // Create initial record
        await _apiService.updateHealthMetrics(_todayMetrics!);
      }

      // Fetch past 7 days for charts
      final now = DateTime.now();
      _weeklyMetrics = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        try {
          final metrics = await _apiService.getHealthMetrics(date);
          if (metrics != null) {
            _weeklyMetrics.add(metrics);
          } else {
            // Add empty metrics for missing days
            _weeklyMetrics.add(HealthMetrics(date: date));
          }
        } catch (e) {
          _weeklyMetrics.add(HealthMetrics(date: date));
        }
      }

      // Schedule notifications if needed (could be optimized to not reschedule every load)
      if (_settings != null) {
        await _scheduleReminders();
      }
    } catch (e) {
      debugPrint("Error loading health data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWater(int amountMl) async {
    if (_todayMetrics == null) return;

    final newAmount = _todayMetrics!.waterIntake + amountMl;
    final updatedMetrics = _todayMetrics!.copyWith(waterIntake: newAmount);

    _todayMetrics = updatedMetrics;
    notifyListeners(); // Optimistic update

    try {
      final savedMetrics = await _apiService.updateHealthMetrics(
        updatedMetrics,
      );
      _todayMetrics = savedMetrics;
    } catch (e) {
      debugPrint("Error saving water intake: $e");
      // Revert logic could be added here
    }
    notifyListeners();
  }

  Future<void> updateSteps(int steps) async {
    if (_todayMetrics == null) return;

    final updatedMetrics = _todayMetrics!.copyWith(steps: steps);
    _todayMetrics = updatedMetrics;
    notifyListeners();

    try {
      await _apiService.updateHealthMetrics(updatedMetrics);
    } catch (e) {
      debugPrint("Error saving steps: $e");
    }
  }

  Future<void> updateSleep(double hours) async {
    if (_todayMetrics == null) return;

    final updatedMetrics = _todayMetrics!.copyWith(sleepHours: hours);
    _todayMetrics = updatedMetrics;
    notifyListeners();

    try {
      await _apiService.updateHealthMetrics(updatedMetrics);
    } catch (e) {
      debugPrint("Error saving sleep: $e");
    }
  }

  Future<void> updateMood(String mood) async {
    if (_todayMetrics == null) return;

    final updatedMetrics = _todayMetrics!.copyWith(mood: mood);
    _todayMetrics = updatedMetrics;
    notifyListeners();

    try {
      await _apiService.updateHealthMetrics(updatedMetrics);
    } catch (e) {
      debugPrint("Error saving mood: $e");
    }
  }

  Future<void> updateSettings(HealthSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    try {
      final savedSettings = await _apiService.updateHealthSettings(newSettings);
      _settings = savedSettings;
      await _scheduleReminders();
    } catch (e) {
      debugPrint("Error updating settings: $e");
    }
    notifyListeners();
  }

  Future<void> _scheduleReminders() async {
    if (_settings == null) return;

    final username = await _apiService.getUsername() ?? 'Friend';

    if (_settings!.reminderInterval > 0) {
      _notificationService.scheduleDailyHydration(
        _settings!.reminderInterval,
        username,
      );
    } else {
      _notificationService.cancelAll();
    }
  }
}
