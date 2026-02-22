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
import '../models/income.dart';
import '../models/expense.dart';

// Screens
import 'analytics_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'add_goal_screen.dart';
import 'subscription_screen.dart';
import 'health_screen.dart';
import 'debt_tracking_screen.dart';

// Reusable Widgets
import 'main_budget_screen.dart';
import 'profile_screen.dart';
import '../widgets/savings_summary_card.dart';
import '../widgets/glass_widgets.dart';

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
      // 1. Refresh Dynamic Categories First
      await CategoryService.refreshCategories();
      if (mounted) {
        setState(() {
          _categories = CategoryService.getCategoryNames(includeAll: true);
        });
      }

      await Future.wait([
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
        ApiService().checkRecurringTransactions().then((newExpenses) {
          if (newExpenses.isNotEmpty && mounted) {
            // Trigger Local Notification
            NotificationService().showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: "Bills Paid",
              body:
                  "${newExpenses.length} recurring transaction(s) were processed automatically.",
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
        }),
      ]);

      // --- SMART ALERT LOGIC ---
      if (mounted) {
        final budgets = Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).budgets;
        final List<String> newAlerts = [];

        for (final b in budgets) {
          if (b.progress >= 1.0) {
            newAlerts.add(
              "⚠️ You've exceeded your ${b.category} budget by \$${(b.spent - b.limit).toStringAsFixed(0)}!",
            );
          } else if (b.progress >= 0.85) {
            newAlerts.add(
              "⚠️ You're close to your ${b.category} limit (${(b.progress * 100).toStringAsFixed(0)}% used).",
            );
          }
        }
        setState(() => _alerts = newAlerts);

        // Handle recurrence
        ApiService().checkRecurringTransactions().then((newExpenses) {
          if (newExpenses.isNotEmpty && mounted) {
            // ... existing snackbar logic ...
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "${newExpenses.length} recurring transaction(s) were auto-added.",
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            Provider.of<ExpenseProvider>(
              context,
              listen: false,
            ).fetchExpenses();
          }
        });
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: _glow(theme.colorScheme.primary.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _glow(theme.colorScheme.secondary.withOpacity(0.08)),
          ),

          SafeArea(bottom: false, child: _getScreen()),

          // Floating Glass Nav Bar
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: IgnorePointer(
              ignoring: _isFabExpanded,
              child: _buildFloatingNavBar(),
            ),
          ),

          // Radial Menu Overlay (must be last to render on top)
          if (_isFabExpanded) _buildRadialMenu(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            backgroundColor: _isFabExpanded
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            shape: const CircleBorder(),
            onPressed: _showAddOptions,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _isFabExpanded ? 0.125 : 0,
              child: Icon(
                _isFabExpanded ? Icons.close : Icons.add,
                color: theme.colorScheme.onPrimary,
                size: 32,
              ),
            ),
          ),
        ),
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
    //final theme = Theme.of(context);
    final expProv = Provider.of<ExpenseProvider>(context);
    final incProv = Provider.of<IncomeProvider>(context);
    final subProv = Provider.of<SubscriptionProvider>(context);

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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
        children: [
          _buildTopHeader(),
          if (_alerts.isNotEmpty && !_isSearching) _buildAlertsList(),
          if (_isSearching) _buildFilterSection(),
          const SizedBox(height: 20),
          if (!_isSearching) ...[
            _buildGlassBalanceCard(
              safeBalance,
              incProv.totalIncome,
              expProv.totalSpent,
              reserved,
            ),
            const SizedBox(height: 15),
            _buildSubscriptionShortcut(reserved),
            const SizedBox(height: 15),
            _buildHealthShortcut(),
            const SizedBox(height: 15),
            const SavingsSummaryCard(),
            const SizedBox(height: 30),
          ],
          _sectionLabel(
            _isSearching
                ? "SEARCH RESULTS (${filtered.length})"
                : "RECENT TRANSACTIONS",
          ),
          if (filtered.isEmpty) _buildEmptyState(),
          ..._buildGroupedList(filtered),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    final theme = Theme.of(context);
    final email = Provider.of<AuthProvider>(context).userEmail ?? "User";

    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: GlassBox(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search transactions...",
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _isSearching = false;
                    _searchQuery = "";
                    _searchController.clear();
                  }),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello,",
              style: TextStyle(color: theme.hintColor, fontSize: 14),
            ),
            Text(
              email.split('@')[0],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            GlassIconButton(
              icon: Icons.search_rounded,
              onTap: () => setState(() => _isSearching = true),
            ),
            const SizedBox(width: 10),
            GlassIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassBalanceCard(
    double balance,
    double income,
    double expense,
    double reserved,
  ) {
    final theme = Theme.of(context);
    return GlassBox(
      height: 220,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "SAFE TO SPEND",
            style: TextStyle(
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              currencyFormat.format(balance),
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
            ),
          ),
          if (reserved > 0)
            Text(
              "After ${currencyFormat.format(reserved)} in monthly bills",
              style: TextStyle(fontSize: 11, color: theme.hintColor),
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniStat(
                Icons.arrow_downward_rounded,
                "Income",
                income,
                Colors.green,
              ),
              const SizedBox(width: 40),
              _miniStat(
                Icons.arrow_upward_rounded,
                "Expenses",
                expense,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, double amount, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionShortcut(double commitment) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
      ).then((_) => _refreshAllData()),
      child: GlassBox(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              Icons.autorenew_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recurring Bills",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "${currencyFormat.format(commitment)} reserved this month",
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthShortcut() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HealthScreen()),
      ),
      child: GlassBox(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.pinkAccent),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Health & Wellness",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Track hydration & reminders",
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // --- LIST HELPERS ---

  List<Widget> _buildGroupedList(List<dynamic> list) {
    List<Widget> widgets = [];
    String lastHeader = "";
    for (var item in list) {
      String currentHeader = _getDateHeader(item.date);
      if (currentHeader != lastHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
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
        );
        lastHeader = currentHeader;
      }
      widgets.add(_buildDismissibleTransaction(item));
    }
    return widgets;
  }

  Widget _buildDismissibleTransaction(dynamic item) {
    return Dismissible(
      key: ValueKey("${item is Income ? 'inc' : 'exp'}_${item.id}"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
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
        child: _buildTransactionItem(item),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic item) {
    final isInc = item is Income;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isInc ? Colors.green : Colors.red).withOpacity(
              0.1,
            ),
            child: Icon(
              CategoryService.getIcon(item.category),
              color: isInc ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "${isInc ? '+' : '-'}${currencyFormat.format(item.amount)}",
            style: TextStyle(
              color: isInc ? Colors.green : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- MODALS ---

  bool _isFabExpanded = false;

  void _showAddOptions() {
    setState(() => _isFabExpanded = !_isFabExpanded);
  }

  Widget _buildRadialMenu() {
    if (!_isFabExpanded) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final actions = [
      _RadialAction(
        icon: Icons.add_circle_outline,
        label: 'Income',
        color: Colors.green,
        onTap: () => const AddIncomeScreen(),
      ),
      _RadialAction(
        icon: Icons.remove_circle_outline,
        label: 'Expense',
        color: Colors.red,
        onTap: () => const AddExpenseScreen(),
      ),
      _RadialAction(
        icon: Icons.autorenew_rounded,
        label: 'Bills',
        color: Colors.purple,
        onTap: () => const SubscriptionScreen(),
      ),
      _RadialAction(
        icon: Icons.savings_outlined,
        label: 'Goal',
        color: Colors.blue,
        onTap: () => const AddGoalScreen(),
      ),
      _RadialAction(
        icon: Icons.handshake,
        label: 'Debt',
        color: Colors.orange,
        onTap: () => const DebtTrackingScreen(),
      ),
    ];

    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isFabExpanded = false),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // Radial buttons
          ...List.generate(actions.length, (index) {
            final distance = 140.0; // Increased distance
            // Spread the 5 buttons evenly
            final dx =
                distance *
                (index == 0
                    ? -1.2
                    : index == 1
                    ? -0.6
                    : index == 2
                    ? 0.0
                    : index == 3
                    ? 0.6
                    : 1.2);
            final dy = -distance * 0.8; // Move buttons higher

            return Positioned(
              bottom: 200 + dy, // Increased base height to clear FAB
              left: MediaQuery.of(context).size.width / 2 - 28 + dx,
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + (index * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isFabExpanded = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => actions[index].onTap(),
                          ),
                        ).then((_) => _refreshAllData());
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: actions[index].color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: actions[index].color.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          actions[index].icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        actions[index].label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return Column(
      children: _alerts
          .map(
            (alert) => Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
            top: 30,
            left: 25,
            right: 25,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set Monthly Budget",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              _sectionLabel("SELECT CATEGORY"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
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
                                Text(cat),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedCategory = val!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel("MONTHLY LIMIT"),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  filled: true,
                  fillColor: colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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

  // --- NAVIGATION HELPERS ---

  Widget _buildFloatingNavBar() {
    return GlassBox(
      height: 75,
      borderRadius: 35,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(0, Icons.home_filled),
          _navIcon(1, Icons.bar_chart_rounded),
          const SizedBox(width: 45),
          _navIcon(2, Icons.account_balance_wallet_rounded),
          _navIcon(3, Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _navIcon(int index, IconData icon) {
    bool selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = index;
        _isSearching = false;
      }),
      child: Icon(
        icon,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.withOpacity(0.5),
        size: 28,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        _sectionLabel("TRANSACTIONS"),
        _buildChipRow(
          ["All", "Income", "Expense"],
          _activeTypeFilter,
          (v) => setState(() => _activeTypeFilter = v),
        ),
        const SizedBox(height: 10),
        _sectionLabel("CATEGORIES"),
        _buildChipRow(
          _categories,
          _activeCategoryFilter,
          (v) => setState(() => _activeCategoryFilter = v),
        ),
      ],
    );
  }

  Widget _buildChipRow(
    List<String> items,
    String current,
    Function(String) onSel,
  ) {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ChoiceChip(
          label: Text(items[i], style: const TextStyle(fontSize: 11)),
          selected: current == items[i],
          onSelected: (_) => onSel(items[i]),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: Text(
        "No transactions found.",
        style: TextStyle(color: Colors.grey),
      ),
    ),
  );
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.blueGrey,
      ),
    ),
  );
  Widget _glow(Color color) => Container(
    height: 300,
    width: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 150, spreadRadius: 50)],
    ),
  );

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

// Helper class for radial menu actions
class _RadialAction {
  final IconData icon;
  final String label;
  final Color color;
  final Widget Function() onTap;

  _RadialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
