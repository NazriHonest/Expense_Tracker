class Expense {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final int? walletId;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.walletId,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      // Ensure id is treated as an int even if it comes as a string
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      title: json['title'] ?? 'No Title',
      // Safe numeric conversion
      amount: (json['amount'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'Other',
      // Handle date safely
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      notes: json['notes'],
      walletId: json['wallet_id'] is String
          ? int.tryParse(json['wallet_id'])
          : json['wallet_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
    if (walletId != null) {
      data['wallet_id'] = walletId;
    }
    return data;
  }
}

class MonthlySummary {
  final String month;
  final double totalAmount;

  MonthlySummary({required this.month, required this.totalAmount});

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json['month'],
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }
}
