import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // Tampilkan konfirmasi sebelum logout
                CustomAlertDialog.show(
                  context,
                  title: AppStrings.confirm,
                  message: AppStrings.confirmLogout,
                  actionLabel: AppStrings.yes,
                  cancelLabel: AppStrings.no,
                  onAction: () async {
                    final nav = Navigator.of(context);
                    nav.pop(); // Tutup dialog
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    // Tampilkan loading
                    LoadingDialog.show(context, message: AppStrings.loading);
                    await authProvider.logout();
                    // Tutup loading menggunakan saved NavigatorState
                    nav.pop();

                    // Pastikan kembali ke layar Login dan hapus semua route sebelumnya
                    nav.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('User tidak ditemukan'),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Text(
                    'Profil Anda',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola informasi akun Anda',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.gray600,
                        ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),

                  // Profile Info
                  Center(
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.gray600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),

                  // Info Fields
                  _buildInfoRow('Nama', user.name),
                  const SizedBox(height: 16),
                  _buildInfoRow('Email', user.email),
                  const SizedBox(height: 16),
                  _buildInfoRow('Role', user.role == 'admin' ? 'Admin' : 'Peserta'),
                  const SizedBox(height: 16),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    _buildInfoRow('Telepon', user.phone!),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    const SizedBox(height: 16),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    _buildInfoRow('Bio', user.bio!),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),

                  // Edit Button
                  CustomElevatedButton(
                    label: 'Edit Profil',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: AppColors.gray300,
        ),
      ],
    );
  }
}