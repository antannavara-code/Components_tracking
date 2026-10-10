import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/drone_provider.dart';
import 'providers/location_provider.dart';
import 'providers/project_provider.dart';
import 'providers/theme_provider.dart';
import 'services/crash_reporter.dart';
import 'screens/login_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrashReporter.instance.install();
  final authProvider = AuthProvider();
  await authProvider.init();
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(MyApp(authProvider: authProvider, themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  const MyApp(
      {super.key, required this.authProvider, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => DroneProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return MaterialApp(
                title: 'QR Asset Tracker',
                debugShowCheckedModeBanner: false,
                themeMode: theme.mode,
                theme: ThemeData(
                  colorSchemeSeed: Colors.blue,
                  useMaterial3: true,
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: Colors.grey.shade100,
                  cardTheme: CardThemeData(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                darkTheme: ThemeData(
                  colorSchemeSeed: Colors.blue,
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  cardTheme: CardThemeData(
                    elevation: 0,
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade700),
                    ),
                  ),
                ),
                home: ErrorBoundary(
                  child: auth.isLoggedIn ? const AppShell() : const LoginScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
