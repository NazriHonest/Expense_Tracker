class Debt {
  final int? id;
  final String title;
  final double amount;
  final DateTime? dueDate;
  final bool
  isOwedByMe; // True = I owe someone (Debt), False = Someone owes me (Loan)
  final String status; // "pending" or "paid"
  final String? notes;
  final int? walletId;

  Debt({
    this.id,
    required this.title,
    required this.amount,
    this.dueDate,
    this.isOwedByMe = true,
    this.status = 'pending',
    this.notes,
    this.walletId,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      isOwedByMe: json['is_owed_by_me'] ?? true,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      walletId: json['wallet_id'] is String
          ? int.tryParse(json['wallet_id'])
          : json['wallet_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'title': title,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
      'is_owed_by_me': isOwedByMe,
      'status': status,
      'notes': notes,
    };
    if (walletId != null) {
      data['wallet_id'] = walletId;
    }
    return data;
  }
}
