import 'package:expense_tracker/models/subscription.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';

class SubscriptionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;

  List<Subscription> get subscriptions => [..._subscriptions];
  bool get isLoading => _isLoading;

  /// Calculates the projected monthly cost of all active subscriptions.
  double get totalMonthlyRequirement {
    return _subscriptions.where((s) => s.isActive).fold(0.0, (sum, sub) {
      switch (sub.frequency) {
        case SubscriptionFrequency.weekly:
          return sum + (sub.amount * 4);
        case SubscriptionFrequency.monthly:
          return sum + sub.amount;
        case SubscriptionFrequency.yearly:
          return sum + (sub.amount / 12);

        // ignore: unreachable_switch_default
        default:
          return sum;
      }
    });
  }

  /// Fetch all subscriptions from the API
  Future<void> fetchSubscriptions() async {
    _isLoading = true;
    // Note: notifyListeners() is optional here depending on your UI strategy

    try {
      _subscriptions = await _apiService.getSubscriptions();

      // Schedule Notifications for upcoming bills
      for (var sub in _subscriptions) {
        if (sub.isActive && sub.nextPaymentDate.isAfter(DateTime.now())) {
          // Schedule for 1 day before
          final triggerDate = sub.nextPaymentDate.subtract(
            const Duration(days: 1),
          );
          if (triggerDate.isAfter(DateTime.now())) {
            NotificationService().scheduleNotification(
              id: sub.id!,
              title: "Upcoming Bill: ${sub.title}",
              body:
                  "\$${sub.amount} is due on ${sub.nextPaymentDate.toString().split(' ')[0]}",
              scheduledDate: triggerDate,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Subscription Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new subscription
  Future<void> addSubscription(Subscription sub) async {
    try {
      final newSub = await _apiService.createSubscription(sub);
      _subscriptions.add(newSub);
      notifyListeners();
    } catch (e) {
      debugPrint("Add Subscription Error: $e");
      rethrow;
    }
  }

  /// Update an existing subscription with server-sync
  Future<void> updateSubscription(int id, Subscription updatedSub) async {
    try {
      final subFromServer = await _apiService.updateSubscription(
        id,
        updatedSub,
      );

      final index = _subscriptions.indexWhere((s) => s.id == id);
      if (index != -1) {
        _subscriptions[index] = subFromServer;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Update Subscription Error: $e");
      rethrow;
    }
  }

  /// Delete a subscription with Optimistic UI rollback
  Future<void> deleteSubscription(int id) async {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final backupSub = _subscriptions[index];

    // 1. Remove immediately from UI
    _subscriptions.removeAt(index);
    notifyListeners();

    try {
      // 2. Request deletion on server
      await _apiService.deleteSubscription(id);
    } catch (e) {
      // 3. Rollback if server fails
      _subscriptions.insert(index, backupSub);
      notifyListeners();
      debugPrint("Delete Subscription Error: $e");
      rethrow;
    }
  }

  /// Helper for logout cleanup
  void clearData() {
    _subscriptions = [];
    notifyListeners();
  }
}
