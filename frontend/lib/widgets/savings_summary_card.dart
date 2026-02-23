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
    final colorScheme = theme.colorScheme;

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
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colorScheme.primary,
                ),
              ),
              if (goals.isNotEmpty)
                TextButton(
                  onPressed: () {
                    /* Navigate to All Goals */
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    textStyle: const TextStyle(fontSize: 12),
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("See All"),
                ),
            ],
          ),
        ),

        // Goals List or Empty State
        goals.isEmpty
            ? _buildEmptyState(context)
            : SizedBox(
                height: 140, // Reduced from 180 to 140
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: goals.length,
                  itemBuilder: (ctx, i) => _GoalMiniCard(goal: goals[i]),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const AddGoalScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12), // Reduced from 16 to 12
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced from 10 to 8
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(
                  10,
                ), // Reduced from 12 to 10
              ),
              child: Icon(
                Icons.add_chart_rounded,
                color: colorScheme.primary,
                size: 18, // Reduced from 20 to 18
              ),
            ),
            const SizedBox(width: 12), // Reduced from 16 to 12
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "No active goals",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13, // Reduced from 14 to 13
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tap to set your first target",
                  style: TextStyle(
                    fontSize: 11, // Reduced from 12 to 11
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalMiniCard extends StatelessWidget {
  final SavingsGoal goal;

  const _GoalMiniCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GoalDetailsScreen(goalId: goal.id!),
        ),
      ),
      child: Container(
        width: 140, // Reduced from 160 to 140
        margin: const EdgeInsets.only(right: 8), // Reduced from 12 to 8
        padding: const EdgeInsets.all(12), // Reduced from 16 to 12
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14), // Slightly reduced from 16
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon with colored background
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8 to 6
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8), // Reduced from 12 to 8
              ),
              child: Icon(
                Icons.savings_rounded,
                color: goal.color,
                size: 16, // Reduced from 18 to 16
              ),
            ),

            // Title
            Text(
              goal.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13, // Reduced from 14 to 13
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Progress Bar
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: goal.progress.clamp(0.0, 1.0),
                    backgroundColor: colorScheme.surfaceContainer,
                    color: goal.color,
                    minHeight: 4, // Reduced from 6 to 4
                  ),
                ),
                const SizedBox(height: 4), // Reduced from 6 to 4
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(goal.progress * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 10, // Reduced from 11 to 10
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "\$${goal.currentAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 10, // Reduced from 11 to 10
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
