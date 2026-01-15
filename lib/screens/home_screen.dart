// lib/screens/home_screen.dart
// (KODE LENGKAP - MENGGUNAKAN INDEXEDSTACK AGAR DATA TIDAK HILANG)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';
import 'profile_screen.dart';
import 'event_list_screen.dart'; // Pastikan import ini ada
import 'qr_scan_screen.dart';
import 'participant_history_screen.dart';
import 'user_management_screen.dart';
import 'admin_dashboard_screen.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // --- (AKHIR PERUBAHAN) ---

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens(context);
    // Clamp index if screens length changed due to role
    final maxIndex = screens.length - 1;
    if (_selectedIndex > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = maxIndex);
      });
    }

    return Scaffold(
      // --- (INI PERBAIKAN UTAMANYA) ---
      // Kita ganti 'body: screens[_selectedIndex]'
      // dengan 'IndexedStack'
      body: IndexedStack(
        index: _selectedIndex, // Hanya tampilkan widget di index ini
        children: screens, // Tumpuk semua halaman di sini
      ),

      // --- (AKHIR PERBAIKAN) ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: _buildBottomNavItems(context),
      ),
    );
  }

  // Build screens dynamically based on user role
  List<Widget> _buildScreens(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;

    if (isAdmin) {
      return [
        const AdminDashboardScreen(),
        EventListScreen(),
        const UserManagementScreen(),
        const ProfileScreen(),
      ];
    }

    return [
      EventListScreen(),
      const QrScanScreen(),
      const ParticipantHistoryScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _buildBottomNavItems(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;

    if (isAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: AppStrings.events,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          activeIcon: Icon(Icons.group),
          label: AppStrings.users,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: AppStrings.account,
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.event_outlined),
        activeIcon: Icon(Icons.event),
        label: AppStrings.events,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_2_outlined),
        activeIcon: Icon(Icons.qr_code_2),
        label: AppStrings.scanner,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: AppStrings.history,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outlined),
        activeIcon: Icon(Icons.person),
        label: AppStrings.account,
      ),
    ];
  }
}

// Scanner Screen moved to its own file: lib/screens/qr_scan_screen.dart
