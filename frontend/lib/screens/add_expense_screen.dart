import 'package:expense_tracker/services/category_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';

import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../services/notification_service.dart';
import '../providers/wallet_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food & Dining';
  int? _selectedWalletId;

  // Recurrence State
  bool _isRecurring = false;
  SubscriptionFrequency _frequency = SubscriptionFrequency.monthly;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount == 0
          ? ''
          : widget.expense?.amount.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');

    if (widget.expense != null) {
      _selectedCategory = CategoryService.safeCategory(
        widget.expense!.category,
      );
      _selectedWalletId = widget.expense!.walletId;
    } else {
      _selectedCategory = CategoryService.getCategoryNames()[0];
    }

    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount greater than 0');
      return;
    }

    final budgetProv = Provider.of<BudgetProvider>(context, listen: false);
    final status = budgetProv.getBudgetByCategory(_selectedCategory);

    if (status != null) {
      final totalSpentAfterThis = status.spent + amount;
      if (totalSpentAfterThis > status.limit) {
        final proceed = await _showBudgetWarning(
          status.limit,
          totalSpentAfterThis - status.limit,
        );
        if (proceed != true) return;
      }
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    final expense = Expense(
      id: widget.expense?.id,
      title: _titleController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      walletId: _selectedWalletId,
    );

    try {
      final expProv = Provider.of<ExpenseProvider>(context, listen: false);
      if (widget.expense == null) {
        await expProv.addExpense(expense);

        // --- Budget Alert Notification ---
        final status = budgetProv.getBudgetByCategory(_selectedCategory);
        if (status != null && (status.spent + amount > status.limit)) {
          final overAmount = (status.spent + amount) - status.limit;
          NotificationService().showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: "Budget Exceeded! ⚠️",
            body:
                "You've gone over your $_selectedCategory budget by \$${overAmount.toStringAsFixed(2)}.",
          );
        }

        // --- Handle Subscription Logic ---
        if (_isRecurring) {
          final subProv = Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          );

          // Create a new subscription starting from the NEXT interval
          final nextDate = _calculateNextDate(_selectedDate, _frequency);

          final newSub = Subscription(
            title: _titleController.text.trim(),
            amount: amount,
            startDate: nextDate,
            category: _selectedCategory,
            frequency: _frequency,
            isActive: true,
          );

          await subProv.addSubscription(newSub);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Recurring bill created starting on ${DateFormat('MMM d').format(nextDate)}',
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        await expProv.updateExpense(widget.expense!.id!, expense);
      }
      if (mounted) Navigator.pop(context);
      Provider.of<BudgetProvider>(context, listen: false).fetchAndSetBudgets();
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _showBudgetWarning(double limit, double overBy) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Budget Alert"),
          ],
        ),
        content: Text(
          "This expense will put you \$${overBy.toStringAsFixed(2)} over your \$${limit.toStringAsFixed(0)} $_selectedCategory budget. Proceed anyway?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  // --- Helper to calculate next start date for subscription ---
  DateTime _calculateNextDate(DateTime start, SubscriptionFrequency freq) {
    switch (freq) {
      case SubscriptionFrequency.weekly:
        return start.add(const Duration(days: 7));
      case SubscriptionFrequency.monthly:
        return DateTime(start.year, start.month + 1, start.day);
      case SubscriptionFrequency.yearly:
        return DateTime(start.year + 1, start.month, start.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(colorScheme),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountHeader(colorScheme),
                      const SizedBox(height: 12),
                      Center(child: _buildBudgetStatus(colorScheme)),
                      const SizedBox(height: 40),
                      _sectionLabel("DETAILS", colorScheme),
                      const SizedBox(height: 8),
                      _buildInputTile(
                        colorScheme,
                        icon: Icons.edit_note_rounded,
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: colorScheme.onSurface),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco(
                            "What did you buy?",
                            colorScheme,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Required"
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryPicker(colorScheme),
                      const SizedBox(height: 16),
                      _buildWalletPicker(colorScheme),
                      const SizedBox(height: 16),
                      _buildDatePicker(colorScheme),
                      const SizedBox(height: 16),

                      // --- RECURRENCE SECTION ---
                      if (widget.expense == null) ...[
                        const SizedBox(height: 8),
                        _sectionLabel("RECURRING PAYMENT", colorScheme),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 2,
                          shadowColor: colorScheme.shadow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  activeColor: colorScheme.primary,
                                  title: Text(
                                    "Repeat this transaction",
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Automatically adds to 'Recurring Bills'",
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: _isRecurring,
                                  onChanged: (val) =>
                                      setState(() => _isRecurring = val),
                                ),

                                if (_isRecurring) ...[
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Frequency",
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      DropdownButton<SubscriptionFrequency>(
                                        value: _frequency,
                                        dropdownColor:
                                            colorScheme.surfaceContainerHighest,
                                        underline: const SizedBox(),
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: colorScheme.primary,
                                        ),
                                        items: SubscriptionFrequency.values.map(
                                          (f) {
                                            String label = f
                                                .toString()
                                                .split('.')
                                                .last;
                                            label =
                                                label[0].toUpperCase() +
                                                label.substring(1);
                                            return DropdownMenuItem(
                                              value: f,
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _frequency = val);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Next bill will be due on ${DateFormat('MMM d, yyyy').format(_calculateNextDate(_selectedDate, _frequency))}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      _sectionLabel("NOTES", colorScheme),
                      const SizedBox(height: 8),
                      _buildInputTile(
                        colorScheme,
                        icon: Icons.notes_rounded,
                        child: TextFormField(
                          controller: _notesController,
                          style: TextStyle(color: colorScheme.onSurface),
                          maxLines: 3,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco(
                            "Optional notes...",
                            colorScheme,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(child: _buildFloatingAction(colorScheme)),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.expense != null ? "Edit Transaction" : "Add Expense",
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildAmountHeader(ColorScheme colorScheme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "AMOUNT",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicWidth(
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              autofocus: widget.expense == null,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: "\$ ",
                prefixStyle: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker(ColorScheme colorScheme) {
    return _buildInputTile(
      colorScheme,
      icon: Icons.category_outlined,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          items: CategoryService.getCategoryNames().map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Row(
                children: [
                  Icon(
                    CategoryService.getIcon(val),
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    val,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildDatePicker(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(colorScheme: colorScheme),
              child: child!,
            );
          },
        );
        if (d != null) setState(() => _selectedDate = d);
      },
      child: _buildInputTile(
        colorScheme,
        icon: Icons.event_note_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
            style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletPicker(ColorScheme colorScheme) {
    return Consumer<WalletProvider>(
      builder: (context, walletProv, _) {
        if (walletProv.wallets.isEmpty) {
          return const SizedBox.shrink();
        }

        if (_selectedWalletId == null && widget.expense == null) {
          final defaultWallet = walletProv.wallets.firstWhere(
            (w) => w.isDefault,
            orElse: () => walletProv.wallets.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedWalletId == null) {
              setState(() => _selectedWalletId = defaultWallet.id);
            }
          });
        }

        return _buildInputTile(
          colorScheme,
          icon: Icons.account_balance_wallet_rounded,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value:
                  _selectedWalletId ??
                  (walletProv.wallets.isNotEmpty
                      ? walletProv.wallets.first.id
                      : null),
              isExpanded: true,
              dropdownColor: colorScheme.surface,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              items: walletProv.wallets.map((wallet) {
                return DropdownMenuItem<int>(
                  value: wallet.id,
                  child: Text(
                    wallet.name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedWalletId = v),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetStatus(ColorScheme colorScheme) {
    final budgetProv = Provider.of<BudgetProvider>(context);
    final status = budgetProv.getBudgetByCategory(_selectedCategory);
    if (status == null) return const SizedBox.shrink();

    final entered = double.tryParse(_amountController.text) ?? 0.0;
    final total = status.spent + entered;
    final isOver = total > status.limit;
    final Color statusColor = isOver ? colorScheme.error : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            (isOver ? colorScheme.errorContainer : colorScheme.primaryContainer)
                .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOver
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            color: statusColor,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            isOver
                ? "Over \$${status.limit.toStringAsFixed(0)} limit"
                : "Within \$${status.limit.toStringAsFixed(0)} limit",
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAction(ColorScheme colorScheme) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset > 0 ? 10 : 16),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Confirm Transaction",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, ColorScheme colorScheme) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 15,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      );

  Widget _sectionLabel(String t, ColorScheme colorScheme) => Padding(
    padding: const EdgeInsets.only(bottom: 4, left: 4),
    child: Text(
      t,
      style: TextStyle(
        color: colorScheme.primary,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );
}
