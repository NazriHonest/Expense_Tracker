class Income {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final int? walletId;

  Income({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.walletId,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      // Handle ID coming as either String or Int
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      title: json['title'] ?? 'Untitled',
      // Safe conversion of num to double
      amount: (json['amount'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'Other',
      // Safe Date Parsing
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
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
