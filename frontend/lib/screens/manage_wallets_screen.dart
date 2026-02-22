import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/glass_widgets.dart';
import 'add_wallet_screen.dart';

class ManageWalletsScreen extends StatelessWidget {
  const ManageWalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Manage Wallets",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _glow(colorScheme.primary.withOpacity(isDark ? 0.15 : 0.05)),
          ),
          Consumer<WalletProvider>(
            builder: (context, walletProv, _) {
              if (walletProv.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (walletProv.wallets.isEmpty) {
                return Center(
                  child: Text(
                    "No wallets yet.\nAdd one to track specific accounts!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: walletProv.wallets.length,
                itemBuilder: (context, index) {
                  final wallet = walletProv.wallets[index];
                  return _buildWalletCard(context, wallet);
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWalletScreen()),
          );
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, Wallet wallet) {
    final theme = Theme.of(context);
    final colorFormat = NumberFormat.simpleCurrency();

    return Dismissible(
      key: ValueKey(wallet.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        Provider.of<WalletProvider>(
          context,
          listen: false,
        ).deleteWallet(wallet.id!);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddWalletScreen(wallet: wallet)),
          );
        },
        child: GlassBox(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(wallet.colorValue).withOpacity(0.2),
                child: Icon(
                  IconData(wallet.iconCode, fontFamily: 'MaterialIcons'),
                  color: Color(wallet.colorValue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (wallet.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Default",
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      colorFormat.format(wallet.balance),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glow(Color c) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: c, blurRadius: 100, spreadRadius: 40)],
    ),
  );
}
