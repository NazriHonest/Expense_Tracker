import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/badge_service.dart';
import '../providers/expense_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/health_provider.dart';
import 'package:intl/intl.dart';

/// Achievement badges screen
class AchievementBadgesScreen extends StatefulWidget {
  const AchievementBadgesScreen({super.key});

  @override
  State<AchievementBadgesScreen> createState() =>
      _AchievementBadgesScreenState();
}

class _AchievementBadgesScreenState extends State<AchievementBadgesScreen> {
  final BadgeService _badgeService = BadgeService();
  bool _showUnlockedOnly = false;

  @override
  void initState() {
    super.initState();
    _badgeService.initialize();
    _checkAndUnlockBadges();
  }

  Future<void> _checkAndUnlockBadges() async {
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);

    final expenses = expenseProvider.expenses;
    final goals = goalProvider.goals;
    final todayMetrics = healthProvider.todayMetrics;

    // Check expense-related badges
    if (expenses.isNotEmpty) {
      _badgeService.unlockBadge(BadgeType.firstExpense);
    }

    // Check savings badges
    for (final goal in goals) {
      if (goal.currentAmount >= goal.targetAmount && goal.targetAmount > 0) {
        _badgeService.unlockBadge(BadgeType.savingsGoal);
      }
      if (goal.currentAmount >= 1000) {
        _badgeService.unlockBadge(BadgeType.emergencyFund);
      }
    }

    // Check total savings
    final totalSavings = goals.fold<double>(
      0,
      (sum, g) => sum + g.currentAmount,
    );
    if (totalSavings >= 1000000) {
      _badgeService.unlockBadge(BadgeType.millionaire);
    }

    // Check health badges
    if (todayMetrics != null) {
      if (todayMetrics.waterIntake >= 2000) {
        // Would need streak tracking for actual implementation
        // _badgeService.unlockBadge(BadgeType.hydrationHero);
      }
      if (todayMetrics.steps >= 10000) {
        // _badgeService.unlockBadge(BadgeType.stepMaster);
      }
      if (todayMetrics.sleepHours >= 8) {
        // _badgeService.unlockBadge(BadgeType.sleepChampion);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allBadges = _badgeService.getAllBadges();
    final unlockedBadges = _badgeService.getUnlockedBadges();
    //final lockedBadges = _badgeService.getLockedBadges();

    final displayBadges = _showUnlockedOnly ? unlockedBadges : allBadges;
    final totalPoints = _badgeService.getTotalPoints();
    final progress = allBadges.isNotEmpty
        ? unlockedBadges.length / allBadges.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAndUnlockBadges,
            tooltip: 'Check Progress',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'Unlocked',
                      '${unlockedBadges.length}/${allBadges.length}',
                      Icons.emoji_events,
                    ),
                    _buildStatCard(
                      'Total Points',
                      totalPoints.toString(),
                      Icons.star,
                    ),
                    _buildStatCard(
                      'Progress',
                      '${(progress * 100).toStringAsFixed(0)}%',
                      Icons.trending_up,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('All'),
                  selected: !_showUnlockedOnly,
                  onSelected: (v) => setState(() => _showUnlockedOnly = !v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Unlocked (${unlockedBadges.length})'),
                  selected: _showUnlockedOnly,
                  onSelected: (v) => setState(() => _showUnlockedOnly = v),
                ),
              ],
            ),
          ),

          // Badges Grid
          Expanded(
            child: displayBadges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showUnlockedOnly
                              ? 'No unlocked badges yet'
                              : 'No badges available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: displayBadges.length,
                    itemBuilder: (context, index) {
                      final badge = displayBadges[index];
                      return _buildBadgeCard(badge);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(AchievementBadge badge) {
    final isUnlocked = _badgeService.isUnlocked(badge.type);

    return Card(
      elevation: isUnlocked ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    badge.color.withOpacity(0.3),
                    badge.color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked ? badge.color : Colors.grey[300],
                  shape: BoxShape.circle,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: badge.color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  badge.icon,
                  color: isUnlocked ? Colors.white : Colors.grey[500],
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isUnlocked ? null : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (isUnlocked && badge.unlockedAt != null)
                Text(
                  DateFormat('MMM d').format(badge.unlockedAt!),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              if (!isUnlocked)
                Text(
                  '+${badge.points} pts',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
