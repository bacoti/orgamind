import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  /// Dummy Scanner Screen (akan di-implement di real flow)
  Widget _buildDummyScannerScreen() {
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      const Center(child: Text('Events Screen')), // Placeholder for Events Screen
      _buildDummyScannerScreen(),
      const Center(child: Text('Check-in History Screen')), // Placeholder for Check-in History Screen
      const Center(child: Text('Account Screen')), // Placeholder for Account Screen
    ];

    return Scaffold(
      body: screens[_selectedIndex],
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
