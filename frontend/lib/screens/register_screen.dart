import 'package:expense_tracker/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _getPasswordStrength(String password) {
    if (password.isEmpty) return null;
    if (password.length < 6) return 'Weak';
    if (password.length < 10) return 'Medium';
    return 'Strong';
  }

  Color _getStrengthColor(String? strength) {
    if (strength == 'Weak') return Colors.redAccent;
    if (strength == 'Medium') return Colors.orangeAccent;
    if (strength == 'Strong') return Colors.greenAccent;
    return Colors.transparent;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account Created! Please sign in.'),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: _glow(
              theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _glow(
              theme.colorScheme.secondary.withOpacity(isDark ? 0.1 : 0.05),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 40),

                      // Applied Global GlassBox here
                      _buildGlassForm(isLoading, theme),

                      const SizedBox(height: 30),
                      _buildFooter(isLoading, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, size: 45, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text(
          'Get Started',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account in seconds',
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassForm(bool isLoading, ThemeData theme) {
    final strength = _getPasswordStrength(_passwordController.text);

    return GlassBox(
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField(
              theme: theme,
              controller: _emailController,
              label: "Email Address",
              icon: Icons.alternate_email_rounded,
              type: TextInputType.emailAddress,
              isLoading: isLoading,
            ),
            const SizedBox(height: 20),
            _buildField(
              theme: theme,
              controller: _passwordController,
              label: "Password",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              obscure: _obscurePassword,
              isLoading: isLoading,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onChanged: (val) => setState(() {}),
            ),
            if (_passwordController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: Row(
                  children: [
                    Text(
                      "Strength: ",
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.5,
                        ),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      strength ?? "",
                      style: TextStyle(
                        color: _getStrengthColor(strength),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 35),
            _buildSubmitButton(isLoading, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    bool isLoading = false,
    VoidCallback? onToggle,
    Function(String)? onChanged,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !isLoading,
      obscureText: isPassword ? obscure : false,
      onChanged: onChanged,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: onToggle,
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
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "Field required";
        if (isPassword && val.length < 6) return "Password too short";
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isLoading, ThemeData theme) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter(bool isLoading, ThemeData theme) {
    return TextButton(
      onPressed: isLoading ? null : () => Navigator.pop(context),
      child: RichText(
        text: TextSpan(
          text: "Already have an account? ",
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          children: [
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
