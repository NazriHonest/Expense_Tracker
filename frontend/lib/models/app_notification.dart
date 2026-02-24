import 'package:flutter/material.dart';

enum AppNotificationType {
  budgetAlert,
  goalProgress,
  goalCompleted,
  recurringBill,
  aiInsight,
  general,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case AppNotificationType.budgetAlert:
        return Icons.warning_amber_rounded;
      case AppNotificationType.goalProgress:
        return Icons.flag_rounded;
      case AppNotificationType.goalCompleted:
        return Icons.emoji_events_rounded;
      case AppNotificationType.recurringBill:
        return Icons.autorenew_rounded;
      case AppNotificationType.aiInsight:
        return Icons.auto_awesome_rounded;
      case AppNotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color color(ColorScheme scheme) {
    switch (type) {
      case AppNotificationType.budgetAlert:
        return scheme.error;
      case AppNotificationType.goalProgress:
        return Colors.blue;
      case AppNotificationType.goalCompleted:
        return Colors.amber;
      case AppNotificationType.recurringBill:
        return Colors.purple;
      case AppNotificationType.aiInsight:
        return Colors.teal;
      case AppNotificationType.general:
        return scheme.primary;
    }
  }
}
