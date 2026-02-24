import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../models/health.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  void initState() {
    super.initState();
    // Defer the load until after existing frame to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    final metrics = healthProvider.todayMetrics;
    final settings = healthProvider.settings;

    if (healthProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Checking settings != null is enough as loadData fetches both
    if (metrics == null || settings == null) {
      return const Center(
        child: Text(
          'Failed to load health data. Please check your connection.',
        ),
      );
    }

    final double progress =
        (metrics.waterIntake /
                (settings.waterGoal > 0 ? settings.waterGoal : 2500))
            .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Wellness'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                _showSettingsDialog(context, settings, healthProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => healthProvider.loadData(),
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),

              // Bento Grid: Left (Steps), Right (Sleep & Mood)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildStepTracker(
                        context,
                        metrics,
                        settings,
                        healthProvider,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildSleepTracker(
                            context,
                            metrics,
                            settings,
                            healthProvider,
                          ),
                          const SizedBox(height: 15),
                          _buildMoodTrackerSmall(
                            context,
                            metrics,
                            healthProvider,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildHydrationCard(
                context,
                metrics,
                settings,
                progress,
                healthProvider,
              ),

              const SizedBox(height: 20),
              _buildWeeklyTrendChart(context, healthProvider),

              if (settings.exerciseReminder) ...[
                const SizedBox(height: 20),
                _buildExerciseSuggestion(context),
              ],

              const SizedBox(height: 20),
              _buildWellnessCard(context),
              const SizedBox(height: 100), // Bottom padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Health",
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          "Today, $dateStr",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStepTracker(
    BuildContext context,
    HealthMetrics metrics,
    HealthSettings settings,
    HealthProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final double progress = (metrics.steps / settings.stepsGoal).clamp(
      0.0,
      1.0,
    );

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_walk,
                  color: Colors.orangeAccent,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    _showStepEntryDialog(context, metrics.steps, provider),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.1,
                  ),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orangeAccent,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${metrics.steps}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'of ${settings.stepsGoal} steps',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTracker(
    BuildContext context,
    HealthMetrics metrics,
    HealthSettings settings,
    HealthProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final double progress = (metrics.sleepHours / settings.sleepGoal).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onTap: () => _showSleepDialog(context, metrics.sleepHours, provider),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.nights_stay,
                    color: Colors.indigoAccent,
                    size: 20,
                  ),
                ),
                SizedBox(
                  height: 36,
                  width: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.indigoAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${metrics.sleepHours}h',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'of ${settings.sleepGoal}h goal',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodTrackerSmall(
    BuildContext context,
    HealthMetrics metrics,
    HealthProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Pick emotion based on string or default
    String moodEmoji = '😐';
    String moodLabel = metrics.mood ?? 'Log Mood';
    if (metrics.mood == 'Tired') moodEmoji = '😫';
    if (metrics.mood == 'Okay') moodEmoji = '😐';
    if (metrics.mood == 'Good') moodEmoji = '🙂';
    if (metrics.mood == 'Great') moodEmoji = '😄';
    if (metrics.mood == 'Super') moodEmoji = '🤩';

    return GestureDetector(
      onTap: () => _showMoodDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.pinkAccent,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(moodEmoji, style: const TextStyle(fontSize: 24)),
              Text(
                moodLabel,
                style: TextStyle(
                  color: moodLabel == 'Log Mood'
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: moodLabel == 'Log Mood'
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepDialog(
    BuildContext context,
    double current,
    HealthProvider provider,
  ) {
    double tempVal = current;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Log Sleep"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${tempVal.toStringAsFixed(1)} hours",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Slider(
                value: tempVal,
                min: 0,
                max: 12,
                divisions: 24,
                activeColor: colorScheme.primary,
                onChanged: (val) => setState(() => tempVal = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            FilledButton(
              onPressed: () {
                provider.updateSleep(tempVal);
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodDialog(BuildContext context, HealthProvider provider) {
    final moods = ['😫', '😐', '🙂', '😄', '🤩'];
    final labels = ['Tired', 'Okay', 'Good', 'Great', 'Super'];
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("How are you feeling?"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(moods.length, (index) {
            return GestureDetector(
              onTap: () {
                provider.updateMood(labels[index]);
                Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(moods[index], style: const TextStyle(fontSize: 32)),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHydrationCard(
    BuildContext context,
    HealthMetrics metrics,
    HealthSettings settings,
    double progress,
    HealthProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hydration',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${metrics.waterIntake} / ${settings.waterGoal} ml',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 24,
              backgroundColor: colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWaterButton(
                context,
                250,
                Icons.water_drop_outlined,
                provider,
              ),
              _buildWaterButton(context, 500, Icons.local_drink, provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton(
    BuildContext context,
    int amount,
    IconData icon,
    HealthProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: () => provider.addWater(amount),
      icon: Icon(icon, size: 20),
      label: Text('+$amount ml'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildWellnessCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wellness Reminders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildReminderTile(
            context,
            Icons.timer_outlined,
            'Take a Break',
            'Remember to stretch every hour.',
            colorScheme.tertiary,
          ),
          const SizedBox(height: 12),
          _buildReminderTile(
            context,
            Icons.bed_outlined,
            'Sleep Well',
            'Aim for 7-8 hours of sleep.',
            Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendChart(BuildContext context, HealthProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final weeklyData = provider.weeklyMetrics;

    if (weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max values for scaling
    final maxSteps = weeklyData
        .map((m) => m.steps)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxWater = weeklyData
        .map((m) => m.waterIntake)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxSleep = weeklyData
        .map((m) => m.sleepHours)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Steps Chart
          _buildMiniChart(
            context,
            'Steps',
            Icons.directions_walk,
            Colors.orangeAccent,
            weeklyData.map((m) => m.steps.toDouble()).toList(),
            maxSteps > 0 ? maxSteps : 10000,
          ),
          const SizedBox(height: 16),

          // Water Chart
          _buildMiniChart(
            context,
            'Hydration (ml)',
            Icons.water_drop,
            colorScheme.primary,
            weeklyData.map((m) => m.waterIntake.toDouble()).toList(),
            maxWater > 0 ? maxWater : 2500,
          ),
          const SizedBox(height: 16),

          // Sleep Chart
          _buildMiniChart(
            context,
            'Sleep (hrs)',
            Icons.nights_stay,
            Colors.indigoAccent,
            weeklyData.map((m) => m.sleepHours).toList(),
            maxSleep > 0 ? maxSleep : 8,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    List<double> data,
    double maxValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final value = index < data.length ? data[index] : 0.0;
            final height = maxValue > 0
                ? (value / maxValue * 40).clamp(2.0, 40.0)
                : 2.0;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [color, color.withValues(alpha: 0.6)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildExerciseSuggestion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.directions_run_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Movement Suggestion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have been sitting for a while! How about a quick 5-minute walk or some desk stretches?',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showStepEntryDialog(
    BuildContext context,
    int currentSteps,
    HealthProvider provider,
  ) {
    final controller = TextEditingController(text: currentSteps.toString());
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter Steps"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: "Steps",
            labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            suffixText: "steps",
            suffixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: colorScheme.primary)),
          ),
          FilledButton(
            onPressed: () {
              final steps = int.tryParse(controller.text) ?? currentSteps;
              provider.updateSteps(steps);
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    HealthSettings settings,
    HealthProvider provider,
  ) {
    final waterGoalController = TextEditingController(
      text: settings.waterGoal.toString(),
    );
    final stepsGoalController = TextEditingController(
      text: settings.stepsGoal.toString(),
    );
    final sleepGoalController = TextEditingController(
      text: settings.sleepGoal.toString(),
    );
    final reminderController = TextEditingController(
      text: settings.reminderInterval.toString(),
    );
    bool exercise = settings.exerciseReminder;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Health Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: waterGoalController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Daily Water Goal (ml)',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stepsGoalController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Daily Steps Goal',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sleepGoalController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Daily Sleep Goal (hours)',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reminderController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Reminder Interval (min)',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: Text(
                      'Exercise Suggestions',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    value: exercise,
                    activeThumbColor: colorScheme.primary,
                    onChanged: (val) {
                      setState(() => exercise = val);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          FilledButton(
            onPressed: () {
              final newSettings = HealthSettings(
                id: settings.id,
                waterGoal: int.tryParse(waterGoalController.text) ?? 2500,
                stepsGoal: int.tryParse(stepsGoalController.text) ?? 10000,
                sleepGoal: double.tryParse(sleepGoalController.text) ?? 8.0,
                reminderInterval: int.tryParse(reminderController.text) ?? 60,
                breakInterval: settings.breakInterval,
                exerciseReminder: exercise,
              );
              provider.updateSettings(newSettings);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
