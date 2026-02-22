import 'package:flutter/material.dart';
import 'package:expense_tracker/services/api_service.dart';

class CategoryService {
  // The Single Source of Truth for Categories and Icons
  // The Base Categories (Default)
  static final Map<String, IconData> _defaultCategories = {
    'Food & Dining': Icons.restaurant_rounded,
    'Transportation': Icons.directions_car_rounded,
    'Shopping': Icons.local_mall_rounded,
    'Entertainment': Icons.confirmation_number_rounded,
    'Bills & Utilities': Icons.lightbulb_rounded,
    'Healthcare': Icons.medical_information_rounded,
    'Education': Icons.school_rounded,
    'Travel': Icons.explore_rounded,
    'Savings': Icons.savings_rounded,
    'Other': Icons.widgets_rounded,
  };

  static Map<String, IconData> _combinedCategories = {..._defaultCategories};
  static List<Map<String, dynamic>> _customCategoryData =
      []; // Store full data (id, color, etc)

  // Initialize/Refresh from API
  static Future<void> refreshCategories() async {
    try {
      final customCats = await ApiService().getCategories();
      _customCategoryData = customCats;
      final Map<String, IconData> newMap = {..._defaultCategories};

      for (var cat in customCats) {
        newMap[cat['name']] = IconData(
          cat['icon_code'],
          fontFamily: 'MaterialIcons',
        );
      }
      _combinedCategories = newMap;
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  // Get all names
  static List<String> getCategoryNames({bool includeAll = false}) {
    List<String> names = _combinedCategories.keys.toList();
    if (includeAll) {
      names.insert(0, 'All');
    }
    return names;
  }

  // Safely get icon
  static IconData getIcon(String category) {
    return _combinedCategories[category] ?? Icons.help_outline_rounded;
  }

  // Get color for category (if custom)
  static Color? getCategoryColor(String category) {
    final custom = _customCategoryData.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {},
    );
    if (custom.isNotEmpty) {
      return Color(custom['color_value']);
    }
    return null; // use default UI color logic
  }

  static String safeCategory(String? category) {
    if (category != null && _combinedCategories.containsKey(category)) {
      return category;
    }
    return 'Other';
  }

  static List<Map<String, dynamic>> get customCategories => _customCategoryData;
}
