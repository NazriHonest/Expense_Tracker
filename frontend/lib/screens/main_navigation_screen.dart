// ignore_for_file: use_build_context_synchronously

import 'package:expense_tracker/core/theme/finance_colors.dart';
import 'package:expense_tracker/services/category_service.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Providers & Models
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/notification_provider.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/app_notification.dart';

// Screens
import 'analytics_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'add_goal_screen.dart';
import 'subscription_screen.dart';
import 'health_screen.dart';
import 'debt_tracking_screen.dart';
import 'notification_center_screen.dart';

// Reusable Widgets
import 'main_budget_screen.dart';
import 'profile_screen.dart';
import '../widgets/savings_summary_card.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedTab = 0;
  final currencyFormat = NumberFormat.simpleCurrency();
  bool _isLoading = true;

  // Search & Filter States
  bool _isSearching = false;
  String _searchQuery = "";
  String _activeTypeFilter = "All";
  String _activeCategoryFilter = "All";
  final TextEditingController _searchController = TextEditingController();
  List<String> _alerts = [];

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = CategoryService.getCategoryNames(includeAll: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAllData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Background non-blocking task for subscriptions
      ApiService()
          .checkRecurringTransactions()
          .then((newExpenses) {
            if (newExpenses.isNotEmpty && mounted) {
              // Trigger Local Notification
              NotificationService().showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: "Bills Paid",
                body:
                    "${newExpenses.length} recurring transaction(s) were processed automatically.",
              );
              // Push to in-app notification center
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).addNotification(
                title: 'Recurring Bills Processed',
                body:
                    '${newExpenses.length} recurring transaction(s) were auto-added to your expenses.',
                type: AppNotificationType.recurringBill,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${newExpenses.length} recurring transaction(s) were auto-added.",
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
              // Refresh expenses to show the new ones
              Provider.of<ExpenseProvider>(
                context,
                listen: false,
              ).fetchExpenses();
            }
          })
          .catchError((e) {
            debugPrint("Recurring logic error: $e");
          });

      await Future.wait([
        CategoryService.refreshCategories().then((_) {
          if (mounted) {
            setState(() {
              _categories = CategoryService.getCategoryNames(includeAll: true);
            });
          }
        }),
        Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(),
        Provider.of<IncomeProvider>(context, listen: false).fetchIncomes(),
        Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).fetchAndSetBudgets(),
        Provider.of<GoalProvider>(context, listen: false).fetchGoals(),
        Provider.of<WalletProvider>(context, listen: false).fetchWallets(),
        Provider.of<DebtProvider>(context, listen: false).fetchDebts(),
        Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        ).fetchSubscriptions(),
      ]);

      // --- SMART ALERT LOGIC + IN-APP NOTIFICATIONS ---
      if (mounted) {
        final budgets = Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).budgets;
        final notifProv = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        final List<String> newAlerts = [];

        for (final b in budgets) {
          if (b.progress >= 1.0) {
            final over = (b.spent - b.limit).toStringAsFixed(0);
            newAlerts.add(
              "You've exceeded your ${b.category} budget by \$$over!",
            );
            notifProv.addNotification(
              title: 'Budget Exceeded: ${b.category}',
              body:
                  "You're \$$over over your \$${b.limit.toStringAsFixed(0)} ${b.category} budget.",
              type: AppNotificationType.budgetAlert,
            );
          } else if (b.progress >= 0.85) {
            final pct = (b.progress * 100).toStringAsFixed(0);
            final remaining = (b.limit - b.spent).toStringAsFixed(0);
            newAlerts.add(
              "You're close to your ${b.category} limit ($pct% used).",
            );
            notifProv.addNotification(
              title: 'Budget Warning: ${b.category}',
              body:
                  '$pct% of your ${b.category} budget used. Only \$$remaining remaining.',
              type: AppNotificationType.budgetAlert,
            );
          }
        }
        setState(() => _alerts = newAlerts);

        // --- GOALS PROGRESS NOTIFICATIONS ---
        final goals = Provider.of<GoalProvider>(context, listen: false).goals;
        for (final g in goals) {
          if (g.isCompleted) {
            notifProv.addNotification(
              title: 'Goal Achieved: ${g.title}',
              body:
                  'You\'ve fully funded "${g.title}". Celebrate and set your next goal!',
              type: AppNotificationType.goalCompleted,
            );
          } else if (g.progress >= 0.75) {
            final left = (g.targetAmount - g.currentAmount).toStringAsFixed(0);
            notifProv.addNotification(
              title: 'Almost There: ${g.title}',
              body:
                  '${(g.progress * 100).toStringAsFixed(0)}% funded! Only \$$left left to reach your goal.',
              type: AppNotificationType.goalProgress,
            );
          } else if (g.progress >= 0.5) {
            notifProv.addNotification(
              title: 'Halfway There: ${g.title}',
              body:
                  'You\'re ${(g.progress * 100).toStringAsFixed(0)}% of the way to "${g.title}". Keep saving!',
              type: AppNotificationType.goalProgress,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CORE UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: SafeArea(bottom: false, child: _getScreen()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
            _isSearching = false;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        elevation: 3,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withValues(
          alpha: 0.6,
        ),
        selectedLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        shape: const CircleBorder(),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _getScreen() {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const AnalyticsScreen();
      case 2:
        return MainBudgetScreen(
          budgetProv: Provider.of<BudgetProvider>(context),
          currencyFormat: currencyFormat,
          onAddBudget: _showAddBudgetModal,
        );
      case 3:
        return ProfileScreen(
          onLogout: () =>
              Provider.of<AuthProvider>(context, listen: false).logout(),
        );
      default:
        return _buildHomeTab();
    }
  }

  // --- HOME TAB WIDGETS ---

  Widget _buildHomeTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expProv = Provider.of<ExpenseProvider>(context);
    final incProv = Provider.of<IncomeProvider>(context);
    final subProv = Provider.of<SubscriptionProvider>(context);
    final financeColors = Theme.of(context).extension<FinanceColors>()!;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final double reserved = subProv.totalMonthlyRequirement;
    final double safeBalance =
        incProv.totalIncome - expProv.totalSpent - reserved;

    final List<dynamic> all = [...expProv.expenses, ...incProv.incomes];
    final filtered = all.where((item) {
      final queryMatch = item.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      bool typeMatch =
          _activeTypeFilter == "All" ||
          (_activeTypeFilter == "Income" ? item is Income : item is Expense);
      bool categoryMatch =
          _activeCategoryFilter == "All" ||
          item.category == _activeCategoryFilter;
      return queryMatch && typeMatch && categoryMatch;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return RefreshIndicator(
      onRefresh: _refreshAllData,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Search transactions...",
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => setState(() {
                          _isSearching = false;
                          _searchQuery = "";
                          _searchController.clear();
                        }),
                      ),
                      border: InputBorder.none,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello,",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            Provider.of<AuthProvider>(
                                  context,
                                ).userEmail?.split('@')[0] ??
                                "User",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.search_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () =>
                                setState(() => _isSearching = true),
                          ),
                          Consumer<NotificationProvider>(
                            builder: (context, notifProv, _) {
                              final unreadCount = notifProv.unreadCount;
                              return Stack(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      unreadCount > 0
                                          ? Icons.notifications_active_rounded
                                          : Icons.notifications_none_rounded,
                                      color: unreadCount > 0
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationCenterScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: colorScheme.error,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colorScheme.surface,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            unreadCount > 9
                                                ? '9+'
                                                : '$unreadCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          // Alerts
          if (_alerts.isNotEmpty && !_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: _alerts
                      .map(
                        (alert) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  alert,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

          // Filter Chips (when searching)
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel("TRANSACTION TYPE"),
                    const SizedBox(height: 8),
                    _buildChipRow(
                      ["All", "Income", "Expense"],
                      _activeTypeFilter,
                      (v) => setState(() => _activeTypeFilter = v),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel("CATEGORY"),
                    const SizedBox(height: 8),
                    _buildChipRow(
                      _categories,
                      _activeCategoryFilter,
                      (v) => setState(() => _activeCategoryFilter = v),
                    ),
                  ],
                ),
              ),
            ),

          // Main Content
          if (!_isSearching) ...[
            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shadowColor: colorScheme.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "SAFE TO SPEND",
                          style: TextStyle(
                            color: colorScheme.primary,
                            letterSpacing: 1.5,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          child: Text(
                            currencyFormat.format(safeBalance),
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (reserved > 0)
                          Text(
                            "After ${currencyFormat.format(reserved)} in monthly bills",
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _miniStat(
                              Icons.arrow_downward_rounded,
                              "Income",
                              incProv.totalIncome,
                              financeColors.income, // Using theme color
                            ),
                            const SizedBox(width: 40),
                            _miniStat(
                              Icons.arrow_upward_rounded,
                              "Expenses",
                              expProv.totalSpent,
                              financeColors.expense, // Using theme color
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Net Worth Card
            // Net Worth Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Consumer2<WalletProvider, DebtProvider>(
                  builder: (context, wProv, dProv, _) {
                    final totalWallets = wProv.wallets.fold(
                      0.0,
                      (s, w) => s + w.balance,
                    );
                    final totalDebts = dProv.debts.fold(0.0, (s, d) {
                      if (d.status == 'pending') {
                        return s + (d.isOwedByMe ? -d.amount : d.amount);
                      }
                      return s;
                    });
                    final netWorth = totalWallets + totalDebts;
                    final isPositive = netWorth >= 0;

                    return Card(
                      elevation: 2,
                      shadowColor: colorScheme.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.tertiaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              colorScheme.tertiaryContainer.withValues(
                                alpha: 0.2,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.tertiary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "NET WORTH",
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(netWorth),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: isPositive
                                          ? financeColors.income
                                          : colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPositive
                                      ? financeColors.income.withValues(
                                          alpha: 0.1,
                                        )
                                      : colorScheme.error.withValues(
                                          alpha: 0.1,
                                        ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  color: isPositive
                                      ? financeColors.income
                                      : colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Subscription Shortcut
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shadowColor: colorScheme.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.autorenew_rounded,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      "Recurring Bills",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "${currencyFormat.format(reserved)} reserved this month",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    ).then((_) => _refreshAllData()),
                  ),
                ),
              ),
            ),

            // Health Shortcut
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shadowColor: colorScheme.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: colorScheme.onSecondary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      "Health & Wellness",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Track hydration & reminders",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Savings Summary Card
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SavingsSummaryCard(),
              ),
            ),
          ],

          // Transactions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: _sectionLabel(
                _isSearching
                    ? "SEARCH RESULTS (${filtered.length})"
                    : "RECENT TRANSACTIONS",
              ),
            ),
          ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  "No transactions found.",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ..._buildGroupedList(filtered, financeColors),
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.only(bottom: 150)),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, double amount, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- LIST HELPERS ---

  List<Widget> _buildGroupedList(
    List<dynamic> list,
    FinanceColors financeColors,
  ) {
    List<Widget> slivers = [];
    String lastHeader = "";

    for (var item in list) {
      String currentHeader = _getDateHeader(item.date);
      if (currentHeader != lastHeader) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                currentHeader.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        );
        lastHeader = currentHeader;
      }
      slivers.add(
        SliverToBoxAdapter(child: _buildTransactionItem(item, financeColors)),
      );
    }
    return slivers;
  }

  Widget _buildTransactionItem(dynamic item, FinanceColors financeColors) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInc = item is Income;

    // Get category-specific color
    Color getCategoryColor(String category) {
      switch (category.toLowerCase()) {
        case 'food & dining':
          return Colors.orange;
        case 'shopping':
          return Colors.purple;
        case 'transport':
          return Colors.blue;
        case 'entertainment':
          return Colors.pink;
        case 'bills & utilities':
          return Colors.teal;
        case 'healthcare':
          return Colors.green;
        case 'education':
          return Colors.indigo;
        default:
          return isInc ? financeColors.income : financeColors.expense;
      }
    }

    final categoryColor = getCategoryColor(item.category);
    final amountColor = isInc ? financeColors.income : financeColors.expense;

    return Dismissible(
      key: ValueKey("${item is Income ? 'inc' : 'exp'}_${item.id}"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.onErrorContainer,
          size: 24,
        ),
      ),
      onDismissed: (_) async {
        if (item is Income) {
          await Provider.of<IncomeProvider>(
            context,
            listen: false,
          ).deleteIncome(item.id!);
        } else {
          await Provider.of<ExpenseProvider>(
            context,
            listen: false,
          ).deleteExpense(item.id!);
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => item is Income
                ? AddIncomeScreen(income: item)
                : AddExpenseScreen(expense: item),
          ),
        ).then((_) => _refreshAllData()),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CategoryService.getIcon(item.category),
                  color: categoryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${isInc ? '+' : '-'}${currencyFormat.format(item.amount)}",
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODALS ---

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Add New",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Income',
                    color: Colors.green,
                    onTap: () => const AddIncomeScreen(),
                  ),
                  _buildActionButton(
                    icon: Icons.remove_circle_outline,
                    label: 'Expense',
                    color: Colors.red,
                    onTap: () => const AddExpenseScreen(),
                  ),
                  _buildActionButton(
                    icon: Icons.autorenew_rounded,
                    label: 'Bills',
                    color: Colors.purple,
                    onTap: () => const SubscriptionScreen(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.savings_outlined,
                    label: 'Goal',
                    color: Colors.blue,
                    onTap: () => const AddGoalScreen(),
                  ),
                  _buildActionButton(
                    icon: Icons.handshake,
                    label: 'Debt',
                    color: Colors.orange,
                    onTap: () => const DebtTrackingScreen(),
                  ),
                  const SizedBox(width: 60), // For symmetry
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Widget Function() onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => onTap()),
        ).then((_) => _refreshAllData());
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetModal() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController limitController = TextEditingController();
    String selectedCategory = _categories.firstWhere(
      (c) => c != 'All',
      orElse: () => _categories[0],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Set Monthly Budget",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel("SELECT CATEGORY"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: colorScheme.onSurface),
                dropdownColor: colorScheme.surface,
                items: _categories
                    .where((c) => c != 'All')
                    .map(
                      (String cat) => DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              CategoryService.getIcon(cat),
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cat,
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setModalState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 16),
              _sectionLabel("MONTHLY LIMIT"),
              const SizedBox(height: 8),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  prefixStyle: TextStyle(color: colorScheme.onSurface),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(limitController.text) ?? 0;
                  if (amount > 0) {
                    await Provider.of<BudgetProvider>(
                      context,
                      listen: false,
                    ).addOrUpdateBudget(selectedCategory, amount);
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Budget",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UTILITY WIDGETS ---

  Widget _buildChipRow(
    List<String> items,
    String current,
    Function(String) onSel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      children: items.map((item) {
        final isSelected = current == item;
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onSel(item),
          backgroundColor: colorScheme.surfaceContainerHighest,
          selectedColor: colorScheme.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: isSelected ? 2 : 0,
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: colorScheme.primary,
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return "Today";
    }
    if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      return "Yesterday";
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
