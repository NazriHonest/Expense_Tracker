class HealthMetrics {
  final int? id;
  final DateTime date;
  final int waterIntake; // ml
  final int steps;
  final double sleepHours;
  final String? mood;
  final int caloriesBurned;
  final int activeMinutes;

  HealthMetrics({
    this.id,
    required this.date,
    this.waterIntake = 0,
    this.steps = 0,
    this.sleepHours = 0.0,
    this.mood,
    this.caloriesBurned = 0,
    this.activeMinutes = 0,
  });

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      id: json['id'],
      date: DateTime.parse(json['date']),
      waterIntake: json['water_intake'] ?? 0,
      steps: json['steps'] ?? 0,
      sleepHours: (json['sleep_hours'] ?? 0).toDouble(),
      mood: json['mood'],
      caloriesBurned: json['calories_burned'] ?? 0,
      activeMinutes: json['active_minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'water_intake': waterIntake,
      'steps': steps,
      'sleep_hours': sleepHours,
      'mood': mood,
      'calories_burned': caloriesBurned,
      'active_minutes': activeMinutes,
    };
  }

  HealthMetrics copyWith({
    int? id,
    DateTime? date,
    int? waterIntake,
    int? steps,
    double? sleepHours,
    String? mood,
    int? caloriesBurned,
    int? activeMinutes,
  }) {
    return HealthMetrics(
      id: id ?? this.id,
      date: date ?? this.date,
      waterIntake: waterIntake ?? this.waterIntake,
      steps: steps ?? this.steps,
      sleepHours: sleepHours ?? this.sleepHours,
      mood: mood ?? this.mood,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      activeMinutes: activeMinutes ?? this.activeMinutes,
    );
  }
}

class HealthSettings {
  final int? id;
  final int waterGoal;
  final int stepsGoal;
  final double sleepGoal;
  final int reminderInterval; // minutes
  final int breakInterval; // minutes
  final bool exerciseReminder;

  HealthSettings({
    this.id,
    this.waterGoal = 2500,
    this.stepsGoal = 10000,
    this.sleepGoal = 8.0,
    this.reminderInterval = 60,
    this.breakInterval = 60,
    this.exerciseReminder = true,
  });

  factory HealthSettings.fromJson(Map<String, dynamic> json) {
    return HealthSettings(
      id: json['id'],
      waterGoal: json['water_goal'] ?? 2500,
      stepsGoal: json['steps_goal'] ?? 10000,
      sleepGoal: (json['sleep_goal'] ?? 8.0).toDouble(),
      reminderInterval: json['reminder_interval'] ?? 60,
      breakInterval: json['break_interval'] ?? 60,
      exerciseReminder: json['exercise_reminder'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'water_goal': waterGoal,
      'steps_goal': stepsGoal,
      'sleep_goal': sleepGoal,
      'reminder_interval': reminderInterval,
      'break_interval': breakInterval,
      'exercise_reminder': exerciseReminder,
    };
  }
}
