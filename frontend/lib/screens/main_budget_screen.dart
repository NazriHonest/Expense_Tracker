import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/budget_provider.dart';

class MainBudgetScreen extends StatelessWidget {
  final BudgetProvider budgetProv;
  final NumberFormat currencyFormat;
  final VoidCallback onAddBudget;

  const MainBudgetScreen({
    super.key,
    required this.budgetProv,
    required this.currencyFormat,
    required this.onAddBudget,
  });

  int get _daysRemaining {
    DateTime now = DateTime.now();
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayOfMonth.day - now.day + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(context, theme, colorScheme),
            const SizedBox(height: 20),
            Expanded(
              child: budgetProv.isLoading
                  ? _buildShimmerLoading(context)
                  : budgetProv.budgets.isEmpty
                  ? _buildEmptyState(theme, colorScheme)
                  : ListView.builder(
                      itemCount: budgetProv.budgets.length,
                      padding: const EdgeInsets.only(bottom: 150),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final budget = budgetProv.budgets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Dismissible(
                            key: Key(budget.id.toString()),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) =>
                                budgetProv.deleteBudget(budget.id!),
                            background: _buildDeleteBackground(colorScheme),
                            child: _buildBudgetProgressCard(context, budget),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Budgets",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              "Daily spending allowance calculated",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _circularIconButton(context, Icons.add_rounded, onAddBudget),
      ],
    );
  }

  Widget _buildBudgetProgressCard(BuildContext context, dynamic budget) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double progress = (budget.spent / budget.limit).clamp(0.0, 1.0);
    final double remaining = budget.limit - budget.spent;
    final bool isOver = budget.spent > budget.limit;
    final double dailyAllowance = remaining > 0
        ? remaining / _daysRemaining
        : 0;

    Color stateColor = isOver
        ? colorScheme.error
        : (progress > 0.8 ? Colors.orangeAccent : colorScheme.primary);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.category,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (!isOver)
                _buildDailyBadge(colorScheme, stateColor, dailyAllowance),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Track - Fixed contrast
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(stateColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountLabel(
                "Spent",
                budget.spent,
                colorScheme.onSurfaceVariant,
                theme,
              ),
              _amountLabel(
                isOver ? "Over" : "Remaining",
                remaining.abs(),
                stateColor,
                theme,
                isBold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circularIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onPrimary, size: 24),
      ),
    );
  }

  // --- SUPPORTING UI ---

  Widget _buildDailyBadge(ColorScheme colorScheme, Color color, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        "${currencyFormat.format(amount)} / day left",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _amountLabel(
    String label,
    double amount,
    Color color,
    ThemeData theme, {
    bool isBold = false,
  }) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_graph_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Set a limit to start tracking",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: colorScheme.onSurface.withValues(alpha: 0.05),
        highlightColor: colorScheme.onSurface.withValues(alpha: 0.15),
        child: Container(
          height: 160,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(ColorScheme colorScheme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.delete_forever_rounded,
        color: colorScheme.onErrorContainer,
        size: 28,
      ),
    );
  }
}
