import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../providers/income_provider.dart';
import '../providers/wallet_provider.dart';

class AddIncomeScreen extends StatefulWidget {
  final Income? income;
  const AddIncomeScreen({super.key, this.income});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Salary';
  bool _isSaving = false;
  int? _selectedWalletId;

  final Map<String, IconData> _categories = {
    'Salary': Icons.payments_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Investment': Icons.trending_up_rounded,
    'Gift': Icons.redeem_rounded,
    'Refund': Icons.assignment_return_rounded,
    'Other': Icons.add_circle_outline_rounded,
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.income?.title ?? '');
    _amountController = TextEditingController(
      text: widget.income?.amount == 0
          ? ''
          : widget.income?.amount.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.income?.notes ?? '');
    if (widget.income != null) {
      _selectedDate = widget.income!.date;
      _selectedCategory = widget.income!.category;
      _selectedWalletId = widget.income!.walletId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount greater than 0');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final incomeData = Income(
      id: widget.income?.id,
      title: _titleController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      walletId: _selectedWalletId,
    );

    try {
      final provider = Provider.of<IncomeProvider>(context, listen: false);
      if (widget.income != null) {
        await provider.updateIncome(widget.income!.id!, incomeData);
      } else {
        await provider.addIncome(incomeData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final incomeAccent = isDark ? Colors.greenAccent : Colors.green.shade600;

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
                      _buildAmountHeader(colorScheme, incomeAccent),
                      const SizedBox(height: 40),
                      _sectionLabel("SOURCE DETAILS", colorScheme),
                      const SizedBox(height: 8),
                      _buildInputTile(
                        colorScheme,
                        icon: Icons.edit_document,
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: colorScheme.onSurface),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco(
                            "Where did this come from?",
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
                      _sectionLabel("ADDITIONAL INFO", colorScheme),
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
                            "Add a note (Optional)",
                            colorScheme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: _buildFloatingAction(isDark, colorScheme, incomeAccent),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      backgroundColor: colorScheme.surface,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.income != null ? "Edit Income" : "Add Income",
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildAmountHeader(ColorScheme colorScheme, Color accent) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "CASH IN",
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
              autofocus: widget.income == null,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: "+ \$ ",
                prefixStyle: TextStyle(
                  color: accent,
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
              color: accent,
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
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
      icon: Icons.grid_view_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          items: _categories.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(
                        e.value,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        e.key,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
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
        icon: Icons.calendar_month_rounded,
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

        if (_selectedWalletId == null && widget.income == null) {
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

  Widget _buildFloatingAction(
    bool isDark,
    ColorScheme colorScheme,
    Color accent,
  ) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset > 0 ? 10 : 16),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveIncome,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : Text(
                widget.income != null ? "Update Income" : "Confirm Income",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
