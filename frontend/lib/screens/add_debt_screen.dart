import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debt;
  const AddDebtScreen({super.key, this.debt});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  bool _isOwedByMe = true;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    print('🔵 [AddDebtScreen] initState called');
    print(
      '🔵 [AddDebtScreen] Editing debt: ${widget.debt != null ? 'YES (ID: ${widget.debt!.id})' : 'NO (Creating new)'}',
    );

    _titleController = TextEditingController(text: widget.debt?.title ?? '');
    _amountController = TextEditingController(
      text: widget.debt?.amount == null ? '' : widget.debt!.amount.toString(),
    );
    _notesController = TextEditingController(text: widget.debt?.notes ?? '');

    if (widget.debt != null) {
      _isOwedByMe = widget.debt!.isOwedByMe;
      _dueDate = widget.debt!.dueDate;
      print('🔵 [AddDebtScreen] Loading existing debt:');
      print('🔵 [AddDebtScreen]   - Title: ${widget.debt!.title}');
      print('🔵 [AddDebtScreen]   - Amount: ${widget.debt!.amount}');
      print(
        '🔵 [AddDebtScreen]   - Type: ${widget.debt!.isOwedByMe ? 'Debt (I owe)' : 'Loan (I lent)'}',
      );
      print(
        '🔵 [AddDebtScreen]   - Due Date: ${widget.debt!.dueDate?.toIso8601String() ?? 'None'}',
      );
    }
  }

  @override
  void dispose() {
    print('🟢 [AddDebtScreen] dispose called');
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🟡 [AddDebtScreen] didChangeDependencies called');
  }

  Future<void> _saveDebt() async {
    print('🟠 [AddDebtScreen] _saveDebt started');

    if (!_formKey.currentState!.validate()) {
      print('🟠 [AddDebtScreen] Form validation FAILED');
      return;
    }
    print('🟠 [AddDebtScreen] Form validation PASSED');

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    print('🟠 [AddDebtScreen] Parsed amount: $amount');

    final debt = Debt(
      id: widget.debt?.id,
      title: _titleController.text.trim(),
      amount: amount,
      dueDate: _dueDate,
      isOwedByMe: _isOwedByMe,
      notes: _notesController.text.trim(),
      status: widget.debt?.status ?? 'pending',
    );

    print('🟠 [AddDebtScreen] Created debt object:');
    print('🟠 [AddDebtScreen]   - ID: ${debt.id ?? 'new'}');
    print('🟠 [AddDebtScreen]   - Title: ${debt.title}');
    print('🟠 [AddDebtScreen]   - Amount: ${debt.amount}');
    print('🟠 [AddDebtScreen]   - Type: ${debt.isOwedByMe ? 'Debt' : 'Loan'}');
    print(
      '🟠 [AddDebtScreen]   - Due Date: ${debt.dueDate?.toIso8601String() ?? 'None'}',
    );
    print('🟠 [AddDebtScreen]   - Notes: ${debt.notes ?? 'None'}');
    print('🟠 [AddDebtScreen]   - Status: ${debt.status}');

    try {
      final debtProv = Provider.of<DebtProvider>(context, listen: false);
      print('🟠 [AddDebtScreen] Got DebtProvider instance');

      if (widget.debt == null) {
        print('🟠 [AddDebtScreen] Calling createDebt...');
        await debtProv.createDebt(debt);
        print('🟢 [AddDebtScreen] createDebt completed successfully');
      } else {
        print(
          '🟠 [AddDebtScreen] Calling updateDebt with ID: ${widget.debt!.id}...',
        );
        await debtProv.updateDebt(widget.debt!.id!, debt);
        print('🟢 [AddDebtScreen] updateDebt completed successfully');
      }

      if (mounted) {
        print('🟢 [AddDebtScreen] Navigating back');
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('🔴 [AddDebtScreen] ERROR caught: $e');
      print('🔴 [AddDebtScreen] Stack trace: $stackTrace');

      if (mounted) {
        print('🟡 [AddDebtScreen] Showing error snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        print('🟢 [AddDebtScreen] _isSaving set to false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [AddDebtScreen] build called');
    print('🎨 [AddDebtScreen]   - isSaving: $_isSaving');
    print('🎨 [AddDebtScreen]   - isOwedByMe: $_isOwedByMe');
    print(
      '🎨 [AddDebtScreen]   - dueDate: ${_dueDate?.toIso8601String() ?? 'None'}',
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.debt != null ? "Edit Record" : "Add Record"),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel("RECORD TYPE", colorScheme),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: _isOwedByMe,
                    isExpanded: true,
                    dropdownColor: colorScheme.surface,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text("I borrowed money (Debt)"),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text("I lent money (Loan)"),
                      ),
                    ],
                    onChanged: (v) {
                      print(
                        '🟡 [AddDebtScreen] Record type changed to: ${v! ? 'Debt' : 'Loan'}',
                      );
                      setState(() => _isOwedByMe = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel("DETAILS", colorScheme),
              const SizedBox(height: 8),
              _buildInputTile(
                icon: Icons.person_outline_rounded,
                child: TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDeco(
                    _isOwedByMe
                        ? "Who did you borrow from?"
                        : "Who did you lend to?",
                    colorScheme,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      print('🟡 [AddDebtScreen] Title validation FAILED');
                      return "Required";
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      print('🟡 [AddDebtScreen] Title changed: "$value"'),
                ),
              ),
              const SizedBox(height: 16),
              _buildInputTile(
                icon: Icons.attach_money_rounded,
                child: TextFormField(
                  controller: _amountController,
                  style: TextStyle(color: colorScheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: _inputDeco("Amount", colorScheme),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      print('🟡 [AddDebtScreen] Amount validation FAILED');
                      return "Required";
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      print('🟡 [AddDebtScreen] Amount changed: "$value"'),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  print('🟡 [AddDebtScreen] Due date picker opened');
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2050),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(colorScheme: colorScheme),
                        child: child!,
                      );
                    },
                  );
                  if (d != null) {
                    print(
                      '🟡 [AddDebtScreen] Due date selected: ${d.toIso8601String()}',
                    );
                    setState(() => _dueDate = d);
                  } else {
                    print('🟡 [AddDebtScreen] Due date selection cancelled');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _dueDate != null
                            ? DateFormat('MMM d, yyyy').format(_dueDate!)
                            : "Due Date (Optional)",
                        style: TextStyle(
                          color: _dueDate != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel("ADDITIONAL DETAILS", colorScheme),
              const SizedBox(height: 8),
              _buildInputTile(
                icon: Icons.notes_rounded,
                child: TextFormField(
                  controller: _notesController,
                  style: TextStyle(color: colorScheme.onSurface),
                  maxLines: 3,
                  minLines: 1,
                  decoration: _inputDeco("Notes (Optional)", colorScheme),
                  onChanged: (value) =>
                      print('🟡 [AddDebtScreen] Notes changed: "$value"'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 16,
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveDebt,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.debt != null ? "Update Record" : "Save Record",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // --- Material 3 Input Component ---
  Widget _buildInputTile({required IconData icon, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

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

  Widget _buildSectionLabel(String t, ColorScheme colorScheme) => Padding(
    padding: const EdgeInsets.only(left: 4),
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
