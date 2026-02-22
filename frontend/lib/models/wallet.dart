class Wallet {
  final int? id;
  final String name;
  final int iconCode;
  final int colorValue;
  final double balance;
  final bool isDefault;

  Wallet({
    this.id,
    required this.name,
    this.iconCode = 57544, // Default icon
    this.colorValue = 4280391411, // Default color
    this.balance = 0.0,
    this.isDefault = false,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      name: json['name'] ?? 'Wallet',
      iconCode: json['icon_code'] ?? 57544,
      colorValue: json['color_value'] ?? 4280391411,
      balance: (json['balance'] ?? 0.0).toDouble(),
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon_code': iconCode,
      'color_value': colorValue,
      'balance': balance,
      'is_default': isDefault,
    };
  }
}
