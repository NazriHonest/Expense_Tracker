import 'package:flutter/material.dart';

/// Achievement badge types
enum BadgeType {
  // Spending badges
  firstExpense,
  budgetMaster,
  frugalWeek,
  noSpendDay,

  // Savings badges
  firstSavings,
  savingsGoal,
  emergencyFund,
  millionaire,

  // Consistency badges
  dailyTracker,
  weeklyTracker,
  monthlyTracker,
  yearTracker,

  // Health badges
  hydrationHero,
  stepMaster,
  sleepChampion,

  // Special badges
  earlyAdopter,
  dataExporter,
  categoryCreator,
  debtFree,
}

/// Achievement Badge model
class AchievementBadge {
  final BadgeType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int points;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  AchievementBadge({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'points': points,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      type: BadgeType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'],
      description: json['description'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      points: json['points'],
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}

/// Badge service to manage achievements
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  final Map<BadgeType, AchievementBadge> _allBadges = {};
  final Set<BadgeType> _unlockedBadges = {};

  /// Initialize all available badges
  void initialize() {
    _allBadges.clear();

    // Spending Badges
    _allBadges[BadgeType.firstExpense] = AchievementBadge(
      type: BadgeType.firstExpense,
      title: 'First Step',
      description: 'Record your first expense',
      icon: Icons.monetization_on,
      color: Colors.green,
      points: 10,
    );

    _allBadges[BadgeType.budgetMaster] = AchievementBadge(
      type: BadgeType.budgetMaster,
      title: 'Budget Master',
      description: 'Stay within budget for an entire month',
      icon: Icons.shield,
      color: Colors.blue,
      points: 50,
    );

    _allBadges[BadgeType.frugalWeek] = AchievementBadge(
      type: BadgeType.frugalWeek,
      title: 'Frugal Week',
      description: 'Spend 20% less than usual for a week',
      icon: Icons.savings,
      color: Colors.teal,
      points: 30,
    );

    _allBadges[BadgeType.noSpendDay] = AchievementBadge(
      type: BadgeType.noSpendDay,
      title: 'No Spend Day',
      description: 'Go a full day without spending',
      icon: Icons.block,
      color: Colors.purple,
      points: 15,
    );

    // Savings Badges
    _allBadges[BadgeType.firstSavings] = AchievementBadge(
      type: BadgeType.firstSavings,
      title: 'Saver Starter',
      description: 'Create your first savings goal',
      icon: Icons.account_balance_wallet,
      color: Colors.amber,
      points: 20,
    );

    _allBadges[BadgeType.savingsGoal] = AchievementBadge(
      type: BadgeType.savingsGoal,
      title: 'Goal Crusher',
      description: 'Complete a savings goal',
      icon: Icons.emoji_events,
      color: Colors.orange,
      points: 100,
    );

    _allBadges[BadgeType.emergencyFund] = AchievementBadge(
      type: BadgeType.emergencyFund,
      title: 'Prepared Mind',
      description: 'Save \$1000 in emergency fund',
      icon: Icons.security,
      color: Colors.red,
      points: 150,
    );

    _allBadges[BadgeType.millionaire] = AchievementBadge(
      type: BadgeType.millionaire,
      title: 'Millionaire',
      description: 'Reach \$1,000,000 in total savings',
      icon: Icons.attach_money,
      color: Colors.yellow,
      points: 1000,
    );

    // Consistency Badges
    _allBadges[BadgeType.dailyTracker] = AchievementBadge(
      type: BadgeType.dailyTracker,
      title: 'Daily Tracker',
      description: 'Track expenses for 7 consecutive days',
      icon: Icons.calendar_today,
      color: Colors.lightBlue,
      points: 40,
    );

    _allBadges[BadgeType.weeklyTracker] = AchievementBadge(
      type: BadgeType.weeklyTracker,
      title: 'Weekly Warrior',
      description: 'Track expenses for 4 consecutive weeks',
      icon: Icons.date_range,
      color: Colors.indigo,
      points: 80,
    );

    _allBadges[BadgeType.monthlyTracker] = AchievementBadge(
      type: BadgeType.monthlyTracker,
      title: 'Monthly Master',
      description: 'Track expenses for 6 consecutive months',
      icon: Icons.calendar_month,
      color: Colors.deepPurple,
      points: 200,
    );

    _allBadges[BadgeType.yearTracker] = AchievementBadge(
      type: BadgeType.yearTracker,
      title: 'Year Champion',
      description: 'Track expenses for a full year',
      icon: Icons.celebration,
      color: Colors.orange.shade300,
      points: 500,
    );

    // Health Badges
    _allBadges[BadgeType.hydrationHero] = AchievementBadge(
      type: BadgeType.hydrationHero,
      title: 'Hydration Hero',
      description: 'Meet water goal for 30 days',
      icon: Icons.water_drop,
      color: Colors.cyan,
      points: 60,
    );

    _allBadges[BadgeType.stepMaster] = AchievementBadge(
      type: BadgeType.stepMaster,
      title: 'Step Master',
      description: 'Walk 10,000 steps for 14 days',
      icon: Icons.directions_walk,
      color: Colors.greenAccent,
      points: 70,
    );

    _allBadges[BadgeType.sleepChampion] = AchievementBadge(
      type: BadgeType.sleepChampion,
      title: 'Sleep Champion',
      description: 'Get 8 hours sleep for 21 days',
      icon: Icons.bedtime,
      color: Colors.indigoAccent,
      points: 80,
    );

    // Special Badges
    _allBadges[BadgeType.earlyAdopter] = AchievementBadge(
      type: BadgeType.earlyAdopter,
      title: 'Early Adopter',
      description: 'Use the app within first week of installation',
      icon: Icons.rocket_launch,
      color: Colors.pink,
      points: 25,
    );

    _allBadges[BadgeType.dataExporter] = AchievementBadge(
      type: BadgeType.dataExporter,
      title: 'Data Pro',
      description: 'Export your financial data',
      icon: Icons.download,
      color: Colors.blueGrey,
      points: 30,
    );

    _allBadges[BadgeType.categoryCreator] = AchievementBadge(
      type: BadgeType.categoryCreator,
      title: 'Customizer',
      description: 'Create a custom category',
      icon: Icons.category,
      color: Colors.deepOrange,
      points: 20,
    );

    _allBadges[BadgeType.debtFree] = AchievementBadge(
      type: BadgeType.debtFree,
      title: 'Debt Free',
      description: 'Pay off all recorded debts',
      icon: Icons.check_circle,
      color: Colors.green,
      points: 300,
    );
  }

  /// Get all badges
  List<AchievementBadge> getAllBadges() {
    return _allBadges.values.toList();
  }

  /// Get unlocked badges
  List<AchievementBadge> getUnlockedBadges() {
    return _allBadges.values
        .where((b) => _unlockedBadges.contains(b.type))
        .toList();
  }

  /// Get locked badges
  List<AchievementBadge> getLockedBadges() {
    return _allBadges.values
        .where((b) => !_unlockedBadges.contains(b.type))
        .toList();
  }

  /// Unlock a badge
  bool unlockBadge(BadgeType type) {
    if (_unlockedBadges.contains(type)) return false;

    _unlockedBadges.add(type);
    final badge = _allBadges[type];
    if (badge != null) {
      debugPrint('🏆 Badge Unlocked: ${badge.title} (+${badge.points} points)');
    }
    return true;
  }

  /// Check if badge is unlocked
  bool isUnlocked(BadgeType type) => _unlockedBadges.contains(type);

  /// Get total points
  int getTotalPoints() {
    return _allBadges.values
        .where((b) => _unlockedBadges.contains(b.type))
        .fold(0, (sum, b) => sum + b.points);
  }

  /// Get progress towards badges
  Map<BadgeType, double> getProgress() {
    return _allBadges.map(
      (key, value) => MapEntry(key, _unlockedBadges.contains(key) ? 1.0 : 0.0),
    );
  }

  /// Load badges from storage
  Future<void> loadBadges(Map<String, dynamic> savedData) async {
    initialize();
    final unlockedTypes = savedData['unlockedBadges'] as List? ?? [];
    for (final typeName in unlockedTypes) {
      try {
        final type = BadgeType.values.firstWhere((e) => e.name == typeName);
        _unlockedBadges.add(type);
      } catch (e) {
        // Ignore invalid badge types
      }
    }
  }

  /// Save badges to storage
  Map<String, dynamic> toJson() {
    return {'unlockedBadges': _unlockedBadges.map((t) => t.name).toList()};
  }
}
