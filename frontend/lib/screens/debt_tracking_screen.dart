import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/glass_widgets.dart';
import 'add_debt_screen.dart';

class DebtTrackingScreen extends StatefulWidget {
  const DebtTrackingScreen({super.key});

  @override
  State<DebtTrackingScreen> createState() => _DebtTrackingScreenState();
}

class _DebtTrackingScreenState extends State<DebtTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Debt & Loans",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
          tabs: const [
            Tab(text: "Debts (I Owe)"),
            Tab(text: "Loans (Owed To Me)"),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: _glow(colorScheme.error.withOpacity(isDark ? 0.15 : 0.05)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _glow(Colors.green.withOpacity(isDark ? 0.15 : 0.05)),
          ),
          Consumer<DebtProvider>(
            builder: (context, debtProv, _) {
              if (debtProv.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final debts = debtProv.debts.where((d) => d.isOwedByMe).toList();
              final loans = debtProv.debts.where((d) => !d.isOwedByMe).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildDebtList(
                    debts,
                    debtProv.totalOwedByMe,
                    colorScheme,
                    true,
                  ),
                  _buildDebtList(
                    loans,
                    debtProv.totalOwedToMe,
                    colorScheme,
                    false,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
        },
        backgroundColor: colorScheme.primary,
        icon: Icon(Icons.add, color: colorScheme.onPrimary),
        label: Text(
          "Add New",
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDebtList(
    List<Debt> list,
    double totalAmount,
    ColorScheme colorScheme,
    bool isDebt,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isDebt
              ? "You don't owe anyone!\nGreat job."
              : "Nobody owes you anything.",
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
        ),
      );
    } // added closing brace here

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GlassBox(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                isDebt ? "TOTAL OUTSTANDING" : "TOTAL OWED TO YOU",
                style: TextStyle(
                  color: isDebt ? colorScheme.error : Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(totalAmount),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...list.map((debt) => _buildDebtCard(debt, colorScheme)),
      ],
    );
  }

  Widget _buildDebtCard(Debt debt, ColorScheme colorScheme) {
    final isPaid = debt.status == 'paid';
    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        Provider.of<DebtProvider>(context, listen: false).deleteDebt(debt.id!);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddDebtScreen(debt: debt)),
          );
        },
        child: GlassBox(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    (isPaid
                            ? Colors.grey
                            : (debt.isOwedByMe
                                  ? colorScheme.error
                                  : Colors.green))
                        .withOpacity(0.2),
                child: Icon(
                  isPaid
                      ? Icons.check_circle
                      : (debt.isOwedByMe
                            ? Icons.money_off
                            : Icons.attach_money),
                  color: isPaid
                      ? Colors.grey
                      : (debt.isOwedByMe ? colorScheme.error : Colors.green),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                        color: isPaid ? Colors.grey : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(debt.amount),
                      style: TextStyle(
                        fontSize: 14,
                        color: isPaid
                            ? Colors.grey
                            : colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (debt.dueDate != null && !isPaid) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Due: ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isPaid)
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.grey,
                  ),
                  onPressed: () => _markAsPaid(debt, colorScheme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsPaid(Debt debt, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<WalletProvider>(
          builder: (context, walletProv, _) {
            final wallets = walletProv.wallets;
            return GlassBox(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Settle Debt",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    debt.isOwedByMe
                        ? "Which account did you pay from?"
                        : "Which account received the funds?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (wallets.isEmpty)
                    const Text("No wallets found. Please create one.")
                  else
                    ...wallets.map(
                      (w) => ListTile(
                        leading: Icon(
                          IconData(w.iconCode, fontFamily: 'MaterialIcons'),
                          color: Color(w.colorValue),
                        ),
                        title: Text(w.name),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final updated = Debt(
                            id: debt.id,
                            title: debt.title,
                            amount: debt.amount,
                            dueDate: debt.dueDate,
                            isOwedByMe: debt.isOwedByMe,
                            notes: debt.notes,
                            status: 'paid',
                            walletId: w.id,
                          );
                          await Provider.of<DebtProvider>(
                            context,
                            listen: false,
                          ).updateDebt(debt.id!, updated);
                          Provider.of<WalletProvider>(
                            context,
                            listen: false,
                          ).fetchWallets(); // Refresh balances
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _glow(Color c) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: c, blurRadius: 100, spreadRadius: 40)],
    ),
  );
}
