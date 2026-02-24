import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/savings_goal.dart';
import '../providers/goal_provider.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();

  bool _isSaving = false;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  String _selectedCategory = 'Savings';
  Color _selectedColor = Colors.blueAccent;

  final Map<String, IconData> _categories = {
    'Savings': Icons.savings_rounded,
    'Travel': Icons.flight_takeoff_rounded,
    'Vehicle': Icons.directions_car_rounded,
    'Home': Icons.home_rounded,
    'Electronics': Icons.devices_rounded,
    'Emergency': Icons.health_and_safety_rounded,
    'Education': Icons.school_rounded,
  };

  final List<Color> _colors = [
    Colors.blueAccent,
    Colors.green.shade600,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.teal.shade600,
    Colors.indigoAccent,
  ];

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final target = double.tryParse(_targetController.text) ?? 0.0;
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid target amount")),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final newGoal = SavingsGoal(
      title: _titleController.text.trim(),
      targetAmount: target,
      currentAmount: 0.0,
      category: _selectedCategory,
      targetDate: _targetDate,
      color: _selectedColor,
    );

    try {
      await Provider.of<GoalProvider>(context, listen: false).addGoal(newGoal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          "Set New Goal",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel("GOAL DETAILS", colorScheme),
              const SizedBox(height: 12),
              _buildInputTile(
                icon: Icons.edit_note_rounded,
                child: TextFormField(
                  controller: _titleController,
                  enabled: !_isSaving,
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                  decoration: _inputDeco("e.g. New Macbook", colorScheme),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Required" : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputTile(
                icon: Icons.attach_money_rounded,
                child: TextFormField(
                  controller: _targetController,
                  enabled: !_isSaving,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDeco("Target Amount", colorScheme),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),

              const SizedBox(height: 32),
              _sectionLabel("CATEGORY", colorScheme),
              const SizedBox(height: 12),
              _buildCategoryWrap(),

              const SizedBox(height: 32),
              _sectionLabel("THEME COLOR", colorScheme),
              const SizedBox(height: 12),
              _buildColorPicker(),

              const SizedBox(height: 48),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Material 3 Input Components ---

  Widget _buildInputTile({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _selectedColor, size: 22),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(colorScheme: Theme.of(context).colorScheme),
                    child: child!,
                  );
                },
              );
              if (d != null) setState(() => _targetDate = d);
            },
      child: _buildInputTile(
        icon: Icons.calendar_today_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            "Target Date: ${DateFormat('MMM dd, yyyy').format(_targetDate)}",
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryWrap() {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.entries.map((e) {
        final isSelected = _selectedCategory == e.key;
        return GestureDetector(
          onTap: _isSaving
              ? null
              : () => setState(() => _selectedCategory = e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedColor.withValues(alpha: 0.2)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? _selectedColor
                    : colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : e.value,
                  size: 18,
                  color: isSelected
                      ? _selectedColor
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  e.key,
                  style: TextStyle(
                    color: isSelected ? _selectedColor : colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        itemBuilder: (ctx, i) {
          final isSelected = _selectedColor == _colors[i];
          return GestureDetector(
            onTap: _isSaving
                ? null
                : () => setState(() => _selectedColor = _colors[i]),
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: _colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _colors[i].withValues(alpha: isSelected ? 0.4 : 0),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Create Goal",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }

  // --- Utility Methods ---

  InputDecoration _inputDeco(String hint, ColorScheme colorScheme) =>
      InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        hintStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );

  Widget _sectionLabel(String t, ColorScheme colorScheme) => Text(
    t,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
      color: colorScheme.primary,
    ),
  );
}
