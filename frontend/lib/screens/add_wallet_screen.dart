import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/glass_widgets.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.wallet != null ? "Edit Wallet" : "Add Wallet"),
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
                  _buildSectionLabel("WALLET DETAILS", colorScheme),
                  GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                  GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                  GlassBox(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Color",
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _colors
                                .map((c) => _buildColorBubble(c))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Icon",
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _icons
                                .map((ic) => _buildIconBubble(ic))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionLabel("SETTINGS", colorScheme),
                  GlassBox(
                    padding: const EdgeInsets.all(16),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Set as default wallet",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _isDefault,
                      activeColor: colorScheme.primary,
                      onChanged: (val) => setState(() => _isDefault = val),
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
            onPressed: _isSaving ? null : _saveWallet,
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

  Widget _buildColorBubble(Color c) {
    final isSelected = _selectedColor == c.value;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = c.value),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildIconBubble(IconData ic) {
    final isSelected = _selectedIcon == ic.codePoint;
    final color = Color(_selectedColor);
    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = ic.codePoint),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          ic,
          color: isSelected
              ? color
              : Theme.of(context).colorScheme.onSurfaceVariant,
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
