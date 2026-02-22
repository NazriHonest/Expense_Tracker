import 'dart:ui';
import 'package:expense_tracker/screens/add_goal_screen.dart';
import 'package:expense_tracker/screens/goal_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../models/savings_goal.dart';

class SavingsSummaryCard extends StatefulWidget {
  const SavingsSummaryCard({super.key});

  @override
  State<SavingsSummaryCard> createState() => _SavingsSummaryCardState();
}

class _SavingsSummaryCardState extends State<SavingsSummaryCard> {
  @override
  Widget build(BuildContext context) {
    final goalProv = Provider.of<GoalProvider>(context);
    final goals = goalProv.goals;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (goalProv.isLoading && goals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SAVINGS GOALS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1.1,
                ),
              ),
              if (goals.isNotEmpty)
                TextButton(
                  onPressed: () {
                    /* Navigate to All Goals */
                  },
                  child: const Text("See All", style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),

        // Goals List or Empty State
        goals.isEmpty
            ? _buildEmptyState(context, isDark)
            : SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior:
                      Clip.none, // Allows glass shadow/glow to breathe
                  itemCount: goals.length,
                  itemBuilder: (ctx, i) =>
                      _GoalMiniCard(goal: goals[i], isDark: isDark),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return _glassContainer(
      isDark: isDark,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const AddGoalScreen())),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.add_chart_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "No active goals",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                "Tap to set your first target",
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalMiniCard extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;
  const _GoalMiniCard({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: _glassContainer(
        isDark: isDark,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GoalDetailsScreen(goalId: goal.id!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: goal.color.withOpacity(0.1),
              radius: 16,
              child: Icon(Icons.savings_rounded, color: goal.color, size: 16),
            ),
            const SizedBox(height: 13),
            Text(
              goal.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 13),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(
                      0.05,
                    ),
                    color: goal.color,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(goal.progress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      "\$${goal.currentAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: goal.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Global helper that uses your exact MainNavigationScreen style
Widget _glassContainer({
  required Widget child,
  required bool isDark,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: child,
        ),
      ),
    ),
  );
}
