import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/category_service.dart';
import '../widgets/glass_widgets.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  // Use a predefined list of available icons for users to pick
  final List<IconData> _availableIcons = [
    Icons.shopping_bag,
    Icons.pets,
    Icons.sports_esports,
    Icons.fitness_center,
    Icons.local_gas_station,
    Icons.flight,
    Icons.school,
    Icons.medical_services,
    Icons.restaurant,
    Icons.movie,
    Icons.work,
    Icons.home,
    Icons.build,
    Icons.directions_car,
    Icons.savings,
    Icons.child_care,
    Icons.music_note,
    Icons.camera_alt,
    Icons.book,
    Icons.wifi,
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category;
  final Color _selectedColor = Colors.blue;
  bool _isSubmitting = false;

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await ApiService().createCategory(
        _nameController.text.trim(),
        _selectedIcon.codePoint,
        _selectedColor.value,
        'expense', // Default to expense for now
      );
      await CategoryService.refreshCategories(); // Refresh global list
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Category Created!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await ApiService().deleteCategory(id);
      await CategoryService.refreshCategories();
      setState(() {}); // Rebuild to update list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customCats = CategoryService.customCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Categories"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Create Section
          GlassBox(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Add New Category",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Category Name (e.g. 'Crypto')",
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableIcons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) => GestureDetector(
                        onTap: () =>
                            setState(() => _selectedIcon = _availableIcons[i]),
                        child: CircleAvatar(
                          backgroundColor: _selectedIcon == _availableIcons[i]
                              ? theme.colorScheme.primary
                              : Colors.grey.withOpacity(0.2),
                          child: Icon(
                            _availableIcons[i],
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _createCategory,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text("Create Category"),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "YOUR CUSTOM CATEGORIES",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),

          Expanded(
            child: customCats.isEmpty
                ? const Center(child: Text("No custom categories yet."))
                : ListView.builder(
                    itemCount: customCats.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (ctx, i) {
                      final cat = customCats[i];
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            IconData(
                              cat['icon_code'],
                              fontFamily: 'MaterialIcons',
                            ),
                            color: Color(cat['color_value']),
                          ),
                          title: Text(cat['name']),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteCategory(cat['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
