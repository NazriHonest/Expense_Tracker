import 'dart:ui';
import 'package:expense_tracker/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/savings_goal.dart';
import '../providers/goal_provider.dart';

class GoalDetailsScreen extends StatelessWidget {
  final String goalId;

  const GoalDetailsScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context) {
    final goalProv = Provider.of<GoalProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final goal = goalProv.goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => SavingsGoal(
        title: "Not Found",
        targetAmount: 1,
        category: "N/A",
        targetDate: DateTime.now(),
      ),
    );

    final colorScheme = theme.colorScheme;
    final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _circularGlassIconButton(
            context,
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.pop(context),
          ),
        ),
        actions: [
          _circularGlassIconButton(
            context,
            Icons.delete_outline_rounded,
            () => _confirmDelete(context, goalProv),
            iconColor: Colors.redAccent,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Background Glow matching the goal's unique color
          Positioned(
            top: -100,
            right: -50,
            child: _glow(goal.color.withOpacity(isDark ? 0.15 : 0.08)),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 140),
            child: Column(
              children: [
                _buildGlassHero(context, goal),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _buildGlassStat(
                      context,
                      "Saved",
                      "\$${goal.currentAmount.toStringAsFixed(0)}",
                      Icons.account_balance_wallet_rounded,
                      goal.color,
                    ),
                    const SizedBox(width: 16),
                    _buildGlassStat(
                      context,
                      "Target",
                      "\$${goal.targetAmount.toStringAsFixed(0)}",
                      Icons.flag_rounded,
                      colorScheme.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildGlassTimeCard(context, goal, daysLeft),

                const SizedBox(height: 32),

                // Progress Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Overall Progress",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${(goal.progress * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: goal.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Track bar using glass styling
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: goal.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: goal.color,
                            boxShadow: [
                              BoxShadow(
                                color: goal.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 60,
        child: FloatingActionButton.extended(
          onPressed: () => _showContributionSheet(context, goal),
          backgroundColor: goal.color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          label: const Text(
            "ADD TO SAVINGS",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  // --- Glass UI Helpers ---

  Widget _buildGlassHero(BuildContext context, SavingsGoal goal) {
    return GlassBox(
      borderRadius: 28,
      child: Container(
        height: 320,
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              goal.category.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: goal.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goal.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: goal.progress,
                    strokeWidth: 14,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    color: goal.color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "\$${(goal.targetAmount - goal.currentAmount).toInt()}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "to go",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassStat(
    BuildContext context,
    String label,
    String val,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: GlassBox(
        borderRadius: 24,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTimeCard(BuildContext context, SavingsGoal goal, int days) {
    return GlassBox(
      borderRadius: 20,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Colors.grey,
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days >= 0 ? "$days Days Left" : "Goal Ended",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Deadline: ${DateFormat('MMM dd, yyyy').format(goal.targetDate)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularGlassIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        borderRadius: 50,
        child: Container(
          height: 45,
          width: 45,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
            size: 20,
          ),
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

  // --- Bottom Sheet ---

  void _showContributionSheet(BuildContext context, SavingsGoal goal) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 32,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Funds",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: "0.00",
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: goal.color,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  final amt = double.tryParse(controller.text) ?? 0;
                  if (amt > 0) {
                    await Provider.of<GoalProvider>(
                      context,
                      listen: false,
                    ).contributeToGoal(goal.id!, amt);
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, GoalProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Goal?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              prov.deleteGoal(goalId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
