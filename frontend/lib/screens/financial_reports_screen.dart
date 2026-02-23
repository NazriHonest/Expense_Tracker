import 'package:expense_tracker/providers/budget_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/goal_provider.dart';
import 'package:expense_tracker/services/pdf_service.dart';
import 'package:expense_tracker/widgets/financial_summary_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Financial Summary",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildMainBalanceCard(theme, colorScheme),
            const SizedBox(height: 32),

            // Header for the detailed list
            Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  "BREAKDOWN",
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FinancialSummaryList(),

            const SizedBox(height: 40),
            _buildExportSection(theme, colorScheme, context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            "CURRENT MONTH STATUS",
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Financial Health",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          _buildHealthIndicator(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(ThemeData theme, ColorScheme colorScheme) {
    // This would be determined by actual financial data
    // For now, we'll set "Good" as active based on sample logic
    final bool isGood = true; // Replace with actual logic
    final bool isFair = false;
    final bool isRisk = false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _healthBit(theme, colorScheme, "Good", Colors.green, isGood),
        _healthBit(theme, colorScheme, "Fair", Colors.orange, isFair),
        _healthBit(theme, colorScheme, "Risk", colorScheme.error, isRisk),
      ],
    );
  }

  Widget _healthBit(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    Color color,
    bool active,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            height: 6,
            width: 45,
            decoration: BoxDecoration(
              color: active ? color : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(3),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? color : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: FilledButton(
        onPressed: () => _handleExport(context),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              "Generate PDF Report",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExport(BuildContext context) {
    final expProv = Provider.of<ExpenseProvider>(context, listen: false);
    final budProv = Provider.of<BudgetProvider>(context, listen: false);
    final goalProv = Provider.of<GoalProvider>(context, listen: false);

    PdfService.generateFinancialReport(
      expenses: expProv.expenses,
      totalSpent: expProv.totalSpent,
      totalSaved: goalProv.goals.fold(0.0, (sum, g) => sum + g.currentAmount),
      budgetLimit: budProv.budgets.fold(0.0, (sum, b) => sum + b.limit),
      budgetSpent: budProv.budgets.fold(0.0, (sum, b) => sum + b.spent),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Preparing report... Check your downloads."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
