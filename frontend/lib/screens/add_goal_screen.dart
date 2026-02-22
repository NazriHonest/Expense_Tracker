import 'package:expense_tracker/widgets/glass_widgets.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Set New Goal",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Glow based on selected goal color
          Positioned(
            top: -50,
            left: -50,
            child: _glow(_selectedColor.withOpacity(isDark ? 0.15 : 0.08)),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 110, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel("GOAL DETAILS", theme.colorScheme),
                  const SizedBox(height: 12),
                  _buildGlassInput(
                    icon: Icons.edit_note_rounded,
                    child: TextFormField(
                      controller: _titleController,
                      enabled: !_isSaving,
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDeco(
                        "e.g. New Macbook",
                        theme.colorScheme,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassInput(
                    icon: Icons.attach_money_rounded,
                    child: TextFormField(
                      controller: _targetController,
                      enabled: !_isSaving,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDeco(
                        "Target Amount",
                        theme.colorScheme,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassDatePicker(),

                  const SizedBox(height: 32),
                  _sectionLabel("CATEGORY", theme.colorScheme),
                  const SizedBox(height: 12),
                  _buildCategoryWrap(),

                  const SizedBox(height: 32),
                  _sectionLabel("THEME COLOR", theme.colorScheme),
                  const SizedBox(height: 12),
                  _buildColorPicker(),

                  const SizedBox(height: 48),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Glass UI Components using Global GlassBox ---

  Widget _buildGlassInput({required IconData icon, required Widget child}) {
    return GlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 20,
      child: Row(
        children: [
          Icon(icon, color: _selectedColor, size: 22),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildGlassDatePicker() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (d != null) setState(() => _targetDate = d);
            },
      child: _buildGlassInput(
        icon: Icons.calendar_today_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            "Target Date: ${DateFormat('MMM dd, yyyy').format(_targetDate)}",
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryWrap() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.entries.map((e) {
        final isSelected = _selectedCategory == e.key;
        return GestureDetector(
          onTap: _isSaving
              ? null
              : () => setState(() => _selectedCategory = e.key),
          child: GlassBox(
            borderRadius: 16,
            // Override background color if selected
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isSelected
                  ? _selectedColor.withOpacity(0.8)
                  : Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_outline_rounded : e.value,
                    size: 18,
                    color: isSelected ? Colors.white : _selectedColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.key,
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
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
                  if (isSelected)
                    BoxShadow(
                      color: _colors[i].withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
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

  Widget _glow(Color color) => Container(
    height: 300,
    width: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 40)],
    ),
  );

  InputDecoration _inputDeco(String hint, ColorScheme colorScheme) =>
      InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        hintStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.3),
        ),
      );

  Widget _sectionLabel(String t, ColorScheme colorScheme) => Text(
    t,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
      color: colorScheme.onSurface.withOpacity(0.5),
    ),
  );
}
