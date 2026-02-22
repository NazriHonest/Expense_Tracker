import 'package:expense_tracker/models/subscription.dart';
import 'package:expense_tracker/providers/subscription_provider.dart';
import 'package:expense_tracker/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      ).fetchSubscriptions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final subscriptions = subProvider.subscriptions;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // 1. Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: _glow(
              theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.07),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _glow(
              theme.colorScheme.secondary.withOpacity(isDark ? 0.08 : 0.04),
            ),
          ),

          // 2. Main Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    "Subscriptions",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMasterCard(
                      theme,
                      subProvider.totalMonthlyRequirement,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(theme, subscriptions.length),
                    const SizedBox(height: 16),

                    if (subProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (subscriptions.isEmpty)
                      _buildEmptyState(theme)
                    else
                      ...subscriptions.map(
                        (sub) => _buildSubscriptionTile(context, theme, sub),
                      ),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubscriptionSheet(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Add Bill",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSectionHeader(ThemeData theme, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Upcoming Bills",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$count Active",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterCard(ThemeData theme, double total) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GlassBox(
        borderRadius: 32,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.7),
                theme.colorScheme.primary.withBlue(200).withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Monthly Commitment",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "\$${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Reserved from daily budget",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(
    BuildContext context,
    ThemeData theme,
    Subscription sub,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(sub.id.toString()),
        direction: DismissDirection.endToStart,
        background: _buildDeleteBackground(),
        onDismissed: (_) {
          HapticFeedback.lightImpact();
          Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          ).deleteSubscription(sub.id!);
        },
        child: GlassBox(
          borderRadius: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(
                  isDark ? 0.05 : 0.1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTileLeading(theme, sub.title[0]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Next: ${DateFormat('MMM dd').format(sub.startDate)}",
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTileTrailing(theme, sub),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileLeading(ThemeData theme, String char) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          char.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTileTrailing(ThemeData theme, Subscription sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "\$${sub.amount.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        Text(
          sub.frequency.name.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.delete_sweep_rounded,
        color: Colors.redAccent,
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text("No active bills", style: theme.textTheme.titleMedium),
          const Opacity(
            opacity: 0.5,
            child: Text(
              "Add subscriptions to improve budget accuracy.",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
    ),
  );

  // --- Logic & Sheet ---

  void _showAddSubscriptionSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var selectedFreq = SubscriptionFrequency.monthly;
    var selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GlassBox(
          // Glass modal
          borderRadius: 32,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 32,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add Subscription",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Service Name",
                      prefixIcon: const Icon(
                        Icons.label_important_outline_rounded,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount",
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SubscriptionFrequency>(
                    initialValue: selectedFreq,
                    decoration: InputDecoration(
                      labelText: "Cycle",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: SubscriptionFrequency.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedFreq = val!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    title: const Text("Billing Date"),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy').format(selectedDate),
                    ),
                    leading: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (titleController.text.isEmpty ||
                            amountController.text.isEmpty) {
                          return;
                        }

                        final sub = Subscription(
                          id: 0,
                          title: titleController.text.trim(),
                          amount: double.tryParse(amountController.text) ?? 0.0,
                          startDate: selectedDate,
                          frequency: selectedFreq,
                          isActive: true,
                        );

                        Provider.of<SubscriptionProvider>(
                          context,
                          listen: false,
                        ).addSubscription(sub);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Save Subscription",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
