import 'package:flutter/material.dart';
import '../models/app_notification.dart';

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      [..._notifications]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String body,
    required AppNotificationType type,
  }) {
    // Prevent duplicate notifications (e.g., from multiple refreshes)
    final isDuplicate = _notifications.any(
      (n) => n.title == title && n.body == body,
    );
    if (isDuplicate) return;

    _notifications.add(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void remove(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void clearData() {
    _notifications.clear();
    notifyListeners();
  }
}
