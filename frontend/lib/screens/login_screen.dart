import 'package:expense_tracker/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        content: Text(
          error.contains('401') ? 'Invalid credentials.' : 'Login failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // 1. Background Glow Orbs
          Positioned(
            top: -50,
            right: -50,
            child: _glow(
              theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _glow(
              theme.colorScheme.secondary.withOpacity(isDark ? 0.1 : 0.05),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    _buildLogo(theme),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Glass Login Form
                    _buildGlassForm(isLoading, theme),

                    const SizedBox(height: 24),
                    _buildFooter(isLoading, theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_graph_rounded,
        size: 45,
        color: Colors.white,
      ),
    );
  }

  Widget _buildGlassForm(bool isLoading, ThemeData theme) {
    return GlassBox(
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildField(
              controller: _emailController,
              label: "Email Address",
              icon: Icons.alternate_email_rounded,
              theme: theme,
              isLoading: isLoading,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _passwordController,
              label: "Password",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              theme: theme,
              isLoading: isLoading,
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(isLoading, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
    bool isLoading = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !isLoading,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      validator: (val) =>
          (val == null || val.isEmpty) ? "Field required" : null,
    );
  }

  Widget _buildSubmitButton(bool isLoading, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'SIGN IN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter(bool isLoading, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        TextButton(
          onPressed: isLoading
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
          child: Text(
            "Register",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _glow(Color color) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 40)],
    ),
  );
}
