import 'package:flutter/material.dart';

@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  final Color income;
  final Color expense;
  final Color savings;
  final Color budget;
  final Color recurring;
  final Color debt;
  final Color wallet;
  final Color health;

  const FinanceColors({
    required this.income,
    required this.expense,
    required this.savings,
    required this.budget,
    required this.recurring,
    required this.debt,
    required this.wallet,
    required this.health,
  });

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? savings,
    Color? budget,
    Color? recurring,
    Color? debt,
    Color? wallet,
    Color? health,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      savings: savings ?? this.savings,
      budget: budget ?? this.budget,
      recurring: recurring ?? this.recurring,
      debt: debt ?? this.debt,
      wallet: wallet ?? this.wallet,
      health: health ?? this.health,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      savings: Color.lerp(savings, other.savings, t)!,
      budget: Color.lerp(budget, other.budget, t)!,
      recurring: Color.lerp(recurring, other.recurring, t)!,
      debt: Color.lerp(debt, other.debt, t)!,
      wallet: Color.lerp(wallet, other.wallet, t)!,
      health: Color.lerp(health, other.health, t)!,
    );
  }
}
