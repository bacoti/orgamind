import 'package:flutter/material.dart';
// No provider required for demo implementation
import '../constants/strings.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final auth = Provider.of<AuthProvider>(context); // future extension if needed

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.users),
        elevation: 1,
      ),
      body: Center(
        child: Text(
          'Daftar pengguna (demo)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Demo: show not implemented
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fitur manajemen pengguna belum diimplementasikan (demo)'),
          ));
        },
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}
