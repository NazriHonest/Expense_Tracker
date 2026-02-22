import 'package:flutter/material.dart';

class SavingsGoal {
  final String? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String category;
  final DateTime targetDate;
  final Color color;

  SavingsGoal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.category,
    required this.targetDate,
    this.color = Colors.blue,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => currentAmount >= targetAmount;

  // Converts Dart object to JSON for Python Backend
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'target_amount': targetAmount, // snake_case for Pydantic
      'current_amount': currentAmount,
      'category': category,
      'target_date': targetDate.toIso8601String(),
      'color_value': color.value,
    };
  }

  // Creates Dart object from Backend JSON
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    try {
      return SavingsGoal(
        id: map['id']?.toString() ?? '',
        title: map['title'] ?? '',
        targetAmount: (map['target_amount'] ?? map['targetAmount'] ?? 0.0)
            .toDouble(),
        currentAmount: (map['current_amount'] ?? map['currentAmount'] ?? 0.0)
            .toDouble(),
        category: map['category'] ?? 'General',
        targetDate: map['target_date'] != null
            ? DateTime.parse(map['target_date'])
            : (map['targetDate'] != null
                  ? DateTime.parse(map['targetDate'])
                  : DateTime.now()),
        color: map['color_value'] != null
            ? Color(map['color_value'])
            : (map['colorValue'] != null
                  ? Color(map['colorValue'])
                  : Colors.blue),
      );
    } catch (e) {
      debugPrint("!!! SAVINGS GOAL PARSING ERROR: $e");
      rethrow;
    }
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? category,
    DateTime? targetDate,
    Color? color,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      color: color ?? this.color,
    );
  }
}
