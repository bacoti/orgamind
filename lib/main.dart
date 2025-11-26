import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
        // Jika sudah login, tampilkan HomeScreen
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }

        // Jika belum login, tampilkan LoginScreen
        return const LoginScreen();
      },
    );
  }
}
