import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/goal_provider.dart';

class FinancialSummaryList extends StatelessWidget {
  const FinancialSummaryList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProv = Provider.of<ExpenseProvider>(context);
    final budgetProv = Provider.of<BudgetProvider>(context);
    final goalProv = Provider.of<GoalProvider>(context);

    // Calculations
    final totalSpent = expenseProv.totalSpent;
    final totalSaved = goalProv.goals.fold(
      0.0,
      (sum, g) => sum + g.currentAmount,
    );
    final totalOutflow = totalSpent + totalSaved;

    final budgetLimit = budgetProv.budgets.fold(0.0, (sum, b) => sum + b.limit);
    final budgetSpent = budgetProv.budgets.fold(0.0, (sum, b) => sum + b.spent);
    final remainingBudget = budgetLimit - budgetSpent;

    final daysRemaining =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day -
        DateTime.now().day +
        1;
    final dailyAllowance = remainingBudget > 0
        ? remainingBudget / daysRemaining
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, "Cash Flow Metrics"),
        _summaryTile(
          "Total Outflow",
          "\$${totalOutflow.toStringAsFixed(2)}",
          Icons.account_balance_wallet_outlined,
          theme,
        ),
        _summaryTile(
          "Actual Savings",
          "\$${totalSaved.toStringAsFixed(2)}",
          Icons.savings_outlined,
          theme,
        ),

        const Divider(height: 32),

        _buildSectionHeader(theme, "Budget Strategy"),
        _summaryTile(
          "Total Planned Limit",
          "\$${budgetLimit.toStringAsFixed(0)}",
          Icons.flag_outlined,
          theme,
        ),
        _summaryTile(
          "Remaining Budget",
          "\$${remainingBudget.toStringAsFixed(2)}",
          Icons.timer_outlined,
          theme,
          valueColor: remainingBudget < 0 ? Colors.redAccent : null,
        ),

        const Divider(height: 32),

        _buildSectionHeader(theme, "Pacing"),
        _summaryTile(
          "Daily Allowance",
          "\$${dailyAllowance.toStringAsFixed(2)}/day",
          Icons.today_rounded,
          theme,
        ),
        _summaryTile(
          "Days Left in Period",
          "$daysRemaining Days",
          Icons.calendar_month_outlined,
          theme,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _summaryTile(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
