import 'package:expense_tracker/providers/budget_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/goal_provider.dart';
import 'package:expense_tracker/services/pdf_service.dart';
import 'package:expense_tracker/widgets/financial_summary_list.dart';
import 'package:expense_tracker/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Financial Summary",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background ambiance glow
          Positioned(
            top: -50,
            right: -50,
            child: _glow(colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05)),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildMainBalanceCard(theme),
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
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const FinancialSummaryList(),

                const SizedBox(height: 40),
                _buildExportSection(theme, context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBalanceCard(ThemeData theme) {
    return GlassBox(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "CURRENT MONTH STATUS",
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Financial Health",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          _buildHealthIndicator(theme),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(ThemeData theme) {
    // Logic could be added here to determine which state is 'active'
    // based on actual provider data (e.g., if spent > budget, set 'Risk' to active)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _healthBit(theme, "Good", Colors.green, true),
        _healthBit(theme, "Fair", Colors.orange, false),
        _healthBit(theme, "Risk", Colors.red, false),
      ],
    );
  }

  Widget _healthBit(ThemeData theme, String label, Color color, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            height: 6,
            width: 45,
            decoration: BoxDecoration(
              color: active ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
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
              color: active
                  ? color
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(ThemeData theme, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _handleExport(context),
        icon: const Icon(Icons.auto_awesome_motion_rounded, size: 20),
        label: const Text(
          "Generate PDF Report",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 60),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
      const SnackBar(
        content: Text("Preparing report... Check your downloads."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _glow(Color color) => Container(
    width: 250,
    height: 250,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
    ),
  );
}
