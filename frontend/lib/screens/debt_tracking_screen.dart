// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/wallet_provider.dart';
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
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: "Debts (I Owe)"),
            Tab(text: "Loans (Owed To Me)"),
          ],
        ),
      ),
      body: Consumer<DebtProvider>(
        builder: (context, debtProv, _) {
          if (debtProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final debts = debtProv.debts.where((d) => d.isOwedByMe).toList();
          final loans = debtProv.debts.where((d) => !d.isOwedByMe).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDebtList(debts, debtProv.totalOwedByMe, colorScheme, true),
              _buildDebtList(loans, debtProv.totalOwedToMe, colorScheme, false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add New",
          style: TextStyle(fontWeight: FontWeight.bold),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDebt
                  ? Icons.money_off_csred_outlined
                  : Icons.attach_money_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isDebt ? "You don't owe anyone!" : "Nobody owes you anything.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDebt
                  ? "Great job! Add a debt to start tracking."
                  : "Add a loan to start tracking.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
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
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
    final debtColor = debt.isOwedByMe ? colorScheme.error : Colors.green;

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.onErrorContainer,
        ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.grey.withValues(alpha: 0.1)
                      : debtColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle_rounded
                      : (debt.isOwedByMe
                            ? Icons.money_off_csred_rounded
                            : Icons.attach_money_rounded),
                  color: isPaid ? Colors.grey : debtColor,
                  size: 24,
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
                        color: isPaid
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(debt.amount),
                      style: TextStyle(
                        fontSize: 14,
                        color: isPaid
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (debt.dueDate != null && !isPaid) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Due: ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}",
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isPaid)
                IconButton(
                  icon: Icon(
                    Icons.check_circle_outline_rounded,
                    color: colorScheme.primary,
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
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<WalletProvider>(
          builder: (context, walletProv, _) {
            final wallets = walletProv.wallets;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  if (wallets.isEmpty)
                    Text(
                      "No wallets found. Please create one.",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  else
                    ...wallets.map(
                      (w) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(w.colorValue).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              IconData(w.iconCode, fontFamily: 'MaterialIcons'),
                              color: Color(w.colorValue),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            w.name,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          trailing: Text(
                            currencyFormat.format(w.balance),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
