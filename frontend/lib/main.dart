import 'package:expense_tracker/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
// Services
import 'services/api_service.dart';
import 'services/notification_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/health_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/debt_provider.dart';

// Screens
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create the AuthProvider first
  final authProvider = AuthProvider();

  // 2. Initialize the ApiService with that AuthProvider
  // This allows the Dio Interceptor to read the token automatically
  ApiService.initialize(authProvider);

  // 3. Initialize Notifications
  await NotificationService().initialize();

  // 4. Optional: Try auto-login before app launch for a smoother splash
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Use ProxyProviders only if you want the data to clear/refresh on login change
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, auth, previous) {
            if (!auth.isAuth) previous?.clearData();
            return previous ?? ExpenseProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, IncomeProvider>(
          create: (_) => IncomeProvider(),
          update: (_, auth, previous) {
            if (!auth.isAuth) previous?.clearData();
            return previous ?? IncomeProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, GoalProvider>(
          create: (_) => GoalProvider(),
          update: (_, auth, previous) {
            if (!auth.isAuth) previous?.clearData();
            return previous ?? GoalProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, BudgetProvider>(
          create: (_) => BudgetProvider(),
          update: (_, auth, previous) {
            return previous ?? BudgetProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, auth, previous) {
            if (!auth.isAuth) previous?.clearData();
            return previous ?? SubscriptionProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider(ApiService())),
        ChangeNotifierProvider(create: (_) => DebtProvider(ApiService())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
      //     theme: AppTheme.light,
      // darkTheme: AppTheme.dark,
      // themeMode: ThemeMode.system,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We listen to AuthProvider to decide which screen to show
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isInitializing) {
      return const SplashScreen();
    }

    if (auth.isAuth) {
      return const MainNavigationScreen();
    }

    // While checking storage, we can show a splash screen
    // You might need an 'isInitializing' bool in AuthProvider if isLoading is used for buttons
    return const LoginScreen();
  }
}
