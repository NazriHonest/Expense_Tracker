import 'package:expense_tracker/widgets/glass_widgets.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // Background Glows - Cohesive with the rest of the app
        Positioned(
          top: -100,
          right: -50,
          child: _glow(colorScheme.primary.withOpacity(isDark ? 0.12 : 0.05)),
        ),
        Positioned(
          bottom: 50,
          left: -80,
          child: _glow(colorScheme.secondary.withOpacity(isDark ? 0.08 : 0.03)),
        ),

        Padding(
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
      ],
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
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        _circularGlassIconButton(context, Icons.add_rounded, onAddBudget),
      ],
    );
  }

  Widget _buildBudgetProgressCard(BuildContext context, dynamic budget) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double progress = (budget.spent / budget.limit).clamp(0.0, 1.0);
    final double remaining = budget.limit - budget.spent;
    final bool isOver = budget.spent > budget.limit;
    final double dailyAllowance = remaining > 0
        ? remaining / _daysRemaining
        : 0;

    Color stateColor = isOver
        ? colorScheme.error
        : (progress > 0.8 ? Colors.orangeAccent : colorScheme.primary);

    return GlassBox(
      borderRadius: 28,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : colorScheme.primary.withOpacity(0.1),
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
                  ),
                ),
                if (!isOver) _buildDailyBadge(stateColor, dailyAllowance),
              ],
            ),
            const Spacer(),
            // Progress Track
            Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: stateColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: stateColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _amountLabel(
                  "Spent",
                  budget.spent,
                  colorScheme.onSurface.withOpacity(0.6),
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
      ),
    );
  }

  Widget _glow(Color color) => Container(
    height: 300,
    width: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 60)],
    ),
  );

  Widget _circularGlassIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GlassBox(
      borderRadius: 45,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 45,
          width: 45,
          color: Colors.transparent, // Ensures the gesture hits
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
      ),
    );
  }

  // --- SUPPORTING UI ---

  Widget _buildDailyBadge(Color color, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
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
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Set a limit to start tracking",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        highlightColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.02),
        child: Container(
          height: 160,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(ColorScheme colorScheme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(
        Icons.delete_forever_rounded,
        color: colorScheme.error,
        size: 28,
      ),
    );
  }
}
