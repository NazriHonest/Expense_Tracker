import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/screens/financial_reports_screen.dart';
import 'package:expense_tracker/screens/manage_categories_screen.dart';
import 'package:expense_tracker/screens/data_export_screen.dart';
import 'package:expense_tracker/screens/manage_wallets_screen.dart';
import 'package:expense_tracker/widgets/glass_widgets.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    final auth = Provider.of<AuthProvider>(context);
    final email = auth.userEmail ?? "User Account";

    return Stack(
      children: [
        // --- 1. Background Glows ---
        Positioned(
          top: -50,
          right: -80,
          child: _glow(colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08)),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: _glow(colorScheme.secondary.withOpacity(isDark ? 0.1 : 0.05)),
        ),

        // --- 2. Content ---
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 150),
          child: Column(
            children: [
              // --- AVATAR SECTION ---
              _buildAnimatedAvatar(theme),
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
              _buildGlassGroup(context, [
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
              _buildGlassGroup(context, [
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
              _buildGlassGroup(context, [
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
              _buildLogoutButton(theme),
            ],
          ),
        ),
      ],
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
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          themeProv.isDarkMode
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        "Dark Mode",
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: CupertinoSwitch(
        activeTrackColor: colorScheme.primary,
        value: themeProv.isDarkMode,
        onChanged: (value) => themeProv.toggleTheme(),
      ),
    );
  }

  Widget _buildGlassGroup(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBox(
      borderRadius: 24,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(children: children),
      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              CupertinoIcons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.2),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        CircleAvatar(
          radius: 56,
          backgroundColor: theme.scaffoldBackgroundColor,
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
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: const Icon(Icons.edit, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return GlassBox(
      borderRadius: 24,
      child: InkWell(
        onTap: onLogout,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.error.withOpacity(0.2)),
            color: colorScheme.error.withOpacity(0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.power, color: colorScheme.error, size: 20),
              const SizedBox(width: 10),
              Text(
                "Logout",
                style: TextStyle(
                  color: colorScheme.error,
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

  Widget _glow(Color color) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)],
    ),
  );
}
