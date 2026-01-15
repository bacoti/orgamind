import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart'; // Import AuthService
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Date Formatting
  await initializeDateFormatting('id_ID', null);

  // CRITICAL: Initialize AuthService before the app starts
  // This prevents the "LateInitializationError: Field '_prefs' has not been initialized" error
  await AuthService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'OrgaMind - Event Management',
        theme: AppTheme.lightTheme,
        locale: const Locale('id', 'ID'),
        home: const _HomeRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Router untuk navigate berdasarkan auth state
class _HomeRouter extends StatelessWidget {
  const _HomeRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Jika sudah login
        if (authProvider.isLoggedIn) {
          // Cek apakah user adalah admin
          if (authProvider.isAdmin) {
            return const AdminDashboardScreen();
          }
          // User biasa tampilkan HomeScreen
          return const HomeScreen();
        }

        // Jika belum login, tampilkan LoginScreen
        return const LoginScreen();
      },
    );
  }
}