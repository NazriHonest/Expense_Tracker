class BudgetStatus {
  final int? id;
  final String category;
  final double limit;
  final double spent;
  final double remaining;
  final double progress; // This is (spent / limit)

  BudgetStatus({
    this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.progress,
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    return BudgetStatus(
      id: json['id'],
      category: json['category'],
      limit: (json['limit'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      progress: (json['progress'] as num).toDouble(),
    );
  }
}
