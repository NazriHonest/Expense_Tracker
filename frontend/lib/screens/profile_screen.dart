import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/screens/debt_tracking_screen.dart';
import 'package:expense_tracker/screens/financial_reports_screen.dart';
import 'package:expense_tracker/screens/manage_categories_screen.dart';
import 'package:expense_tracker/screens/data_export_screen.dart';
import 'package:expense_tracker/screens/manage_wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart' show Provider;

import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = Provider.of<AuthProvider>(context);
    final email = auth.userEmail ?? "User Account";

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 150),
        child: Column(
          children: [
            // --- AVATAR SECTION ---
            _buildAnimatedAvatar(theme, colorScheme),
            const SizedBox(height: 20),
            Text(
              email,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              "Premium Member",
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // --- ANALYTICS & REPORTS GROUP ---
            _buildSectionHeader(context, "Analytics & Reports"),
            _buildCardGroup(context, [
              _profileAction(
                context,
                CupertinoIcons.graph_square_fill,
                "Financial Summary Report",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FinancialReportsScreen(),
                    ),
                  );
                },
              ),
              _profileAction(
                context,
                Icons.category_rounded,
                "Manage Categories",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesScreen(),
                    ),
                  );
                },
              ),
              _profileAction(
                context,
                CupertinoIcons.creditcard_fill,
                "Manage Wallets",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageWalletsScreen(),
                    ),
                  );
                },
              ),
              _profileAction(context, Icons.handshake, "Debt Tracking", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebtTrackingScreen(),
                  ),
                );
              }),
              _profileAction(
                context,
                CupertinoIcons.arrow_down_doc_fill,
                "Export Data (CSV)",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataExportScreen(),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 30),

            // --- ACCOUNT SETTINGS GROUP ---
            _buildSectionHeader(context, "Account Settings"),
            _buildCardGroup(context, [
              _buildDarkModeSwitch(context, theme, colorScheme),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                thickness: 0.5,
              ),
              _profileAction(
                context,
                CupertinoIcons.person_fill,
                "Personal Info",
                () {},
              ),
              _profileAction(
                context,
                CupertinoIcons.shield_fill,
                "Security",
                () {},
              ),
              _profileAction(
                context,
                CupertinoIcons.bell_fill,
                "Notifications",
                () {},
              ),
            ]),

            const SizedBox(height: 30),

            // --- SUPPORT GROUP ---
            _buildSectionHeader(context, "Support & Legal"),
            _buildCardGroup(context, [
              _profileAction(
                context,
                CupertinoIcons.question_circle_fill,
                "Help Center",
                () {},
              ),
              _profileAction(
                context,
                CupertinoIcons.doc_text_fill,
                "Privacy Policy",
                () {},
              ),
            ]),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            _buildLogoutButton(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildDarkModeSwitch(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final themeProv = Provider.of<ThemeProvider>(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          themeProv.isDarkMode
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          color: colorScheme.onPrimary,
          size: 20,
        ),
      ),
      title: Text(
        "Dark Mode",
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: CupertinoSwitch(
        activeTrackColor: colorScheme.primary,
        value: themeProv.isDarkMode,
        onChanged: (value) => themeProv.toggleTheme(),
      ),
    );
  }

  Widget _buildCardGroup(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _profileAction(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
        bottom: Radius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              CupertinoIcons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(ThemeData theme, ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
          ),
          child: Icon(
            CupertinoIcons.person_fill,
            size: 50,
            color: colorScheme.onSurface,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 5,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
            child: const Icon(Icons.edit, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.power,
                color: colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "Logout",
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
