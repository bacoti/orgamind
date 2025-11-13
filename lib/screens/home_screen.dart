// lib/screens/home_screen.dart
// (KODE LENGKAP - MENGGUNAKAN INDEXEDSTACK AGAR DATA TIDAK HILANG)

import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';
import 'profile_screen.dart';
import 'event_list_screen.dart'; // Pastikan import ini ada

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- (INI PERUBAHAN PENTING) ---
  // Kita definisikan list-nya di sini, sekali saja.
  // Jangan lupa 'const' untuk yang statis
  final List<Widget> screens = <Widget>[
    EventListScreen(), // Halaman Acara (tidak const)
    const DummyScannerScreen(), // Halaman Pemindai
    const Center(
        child:
            Text('Check-in History Screen')), // Placeholder untuk Riwayat
    const ProfileScreen(), // Halaman Akun
  ];
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
        items: const [
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
        ],
      ),
    );
  }
}

// --- (KITA PINDAHKAN DUMMY SCANNER KE LUAR AGAR BISA 'const') ---
class DummyScannerScreen extends StatelessWidget {
  const DummyScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.qrScanner),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Pilih acara terlebih dahulu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Buka salah satu acara yang sudah Anda terima\ndan klik "Lanjut ke Check-in"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}