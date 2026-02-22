enum SubscriptionFrequency { weekly, monthly, yearly }

class Subscription {
  final int? id;
  final String title;
  final double amount;
  final DateTime startDate;
  final String category;
  final SubscriptionFrequency frequency;
  final bool isActive;

  Subscription({
    this.id,
    required this.title,
    required this.amount,
    required this.startDate,
    this.category = 'Subscription',
    this.frequency = SubscriptionFrequency.monthly,
    this.isActive = true,
  });

  // Convert JSON (from FastAPI) to Subscription Object
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      category: json['category'] ?? 'Subscription',
      isActive: json['is_active'] ?? true,
      frequency: SubscriptionFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == json['frequency'],
        orElse: () => SubscriptionFrequency.monthly,
      ),
    );
  }

  // Convert Subscription Object to JSON (for FastAPI POST/PUT)
  Map<String, dynamic> toJson() {
    return {
      // 'id': id,
      'title': title,
      'amount': amount,
      'start_date': startDate.toIso8601String(),
      'category': category,
      'frequency': frequency.toString().split('.').last, // e.g., "weekly"
      'is_active': isActive,
    };
  }

  DateTime get nextPaymentDate {
    DateTime now = DateTime.now();
    DateTime next = startDate;

    while (next.isBefore(now)) {
      if (frequency == SubscriptionFrequency.monthly) {
        next = DateTime(next.year, next.month + 1, next.day);
      } else if (frequency == SubscriptionFrequency.weekly) {
        next = next.add(const Duration(days: 7));
      } else {
        next = DateTime(next.year + 1, next.month, next.day);
      }
    }
    return next;
  }
}
