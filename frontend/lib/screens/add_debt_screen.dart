import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../widgets/glass_widgets.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.debt != null ? "Edit Record" : "Add Record"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: _glow(colorScheme.primary.withOpacity(isDark ? 0.15 : 0.05)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("RECORD TYPE", colorScheme),
                  GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _isOwedByMe,
                        isExpanded: true,
                        dropdownColor: colorScheme.surface,
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
                  GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                  GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                      );
                      if (d != null) {
                        print(
                          '🟡 [AddDebtScreen] Due date selected: ${d.toIso8601String()}',
                        );
                        setState(() => _dueDate = d);
                      } else {
                        print(
                          '🟡 [AddDebtScreen] Due date selection cancelled',
                        );
                      }
                    },
                    child: GlassBox(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
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
                                  : colorScheme.onSurfaceVariant.withOpacity(
                                      0.5,
                                    ),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionLabel("ADDITIONAL DETAILS", colorScheme),
                  GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextFormField(
                      controller: _notesController,
                      style: TextStyle(color: colorScheme.onSurface),
                      maxLines: 2,
                      decoration: _inputDeco("Notes", colorScheme),
                      onChanged: (value) =>
                          print('🟡 [AddDebtScreen] Notes changed: "$value"'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                borderRadius: BorderRadius.circular(20),
              ),
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

  InputDecoration _inputDeco(String hint, ColorScheme colorScheme) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.4),
          fontSize: 15,
        ),
        border: InputBorder.none,
      );

  Widget _buildSectionLabel(String t, ColorScheme colorScheme) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      t,
      style: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _glow(Color c) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: c, blurRadius: 100, spreadRadius: 40)],
    ),
  );
}
