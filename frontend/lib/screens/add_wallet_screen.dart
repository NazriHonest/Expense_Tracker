import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';

class AddWalletScreen extends StatefulWidget {
  final Wallet? wallet;
  const AddWalletScreen({super.key, this.wallet});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;

  bool _isDefault = false;
  int _selectedColor = 4280391411; // Blue
  int _selectedIcon = Icons.account_balance_wallet.codePoint;
  bool _isSaving = false;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
  ];

  final List<IconData> _icons = [
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.savings,
    Icons.money,
    Icons.account_balance,
    Icons.request_quote,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.wallet?.balance == null
          ? ''
          : widget.wallet!.balance.toString(),
    );
    if (widget.wallet != null) {
      _isDefault = widget.wallet!.isDefault;
      _selectedColor = widget.wallet!.colorValue;
      _selectedIcon = widget.wallet!.iconCode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final balance = double.tryParse(_balanceController.text) ?? 0.0;

    final wallet = Wallet(
      id: widget.wallet?.id,
      name: _nameController.text.trim(),
      balance: balance,
      colorValue: _selectedColor,
      iconCode: _selectedIcon,
      isDefault: _isDefault,
    );

    try {
      final walletProv = Provider.of<WalletProvider>(context, listen: false);
      if (widget.wallet == null) {
        await walletProv.createWallet(wallet);
      } else {
        await walletProv.updateWallet(widget.wallet!.id!, wallet);
      }
      if (mounted) {
        // Also fetch to ensure consistency
        walletProv.fetchWallets();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.wallet != null ? "Edit Wallet" : "Add Wallet"),
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
              _buildSectionLabel("WALLET DETAILS", colorScheme),
              const SizedBox(height: 8),
              _buildInputTile(
                icon: Icons.wallet_outlined,
                child: TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDeco(
                    "Wallet Name (e.g., Chase Checkings)",
                    colorScheme,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputTile(
                icon: Icons.attach_money_rounded,
                child: TextFormField(
                  controller: _balanceController,
                  style: TextStyle(color: colorScheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: _inputDeco("Initial Balance", colorScheme),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel("APPEARANCE", colorScheme),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Color",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _colors
                              .map((c) => _buildColorBubble(c, colorScheme))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Icon",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _icons
                              .map((ic) => _buildIconBubble(ic, colorScheme))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel("SETTINGS", colorScheme),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shadowColor: colorScheme.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      "Set as default wallet",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      "Default wallet will be selected automatically",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    value: _isDefault,
                    activeColor: colorScheme.primary,
                    onChanged: (val) => setState(() => _isDefault = val),
                  ),
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
            onPressed: _isSaving ? null : _saveWallet,
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
                    widget.wallet != null ? "Update Wallet" : "Add Wallet",
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

  Widget _buildColorBubble(Color c, ColorScheme colorScheme) {
    final isSelected = _selectedColor == c.value;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = c.value),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: colorScheme.onSurface, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  Widget _buildIconBubble(IconData ic, ColorScheme colorScheme) {
    final isSelected = _selectedIcon == ic.codePoint;
    final color = Color(_selectedColor);
    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = ic.codePoint),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
        ),
        child: Icon(
          ic,
          color: isSelected ? color : colorScheme.onSurfaceVariant,
          size: 24,
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
