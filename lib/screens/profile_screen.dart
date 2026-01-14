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

  Future<void> _confirmLogout(BuildContext context) async {
    CustomAlertDialog.show(
      context,
      title: AppStrings.confirm,
      message: AppStrings.confirmLogout,
      actionLabel: AppStrings.yes,
      cancelLabel: AppStrings.no,
      onAction: () async {
        final nav = Navigator.of(context);
        nav.pop();

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        LoadingDialog.show(context, message: AppStrings.loading);
        await authProvider.logout();
        nav.pop();

        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }

  String _displayRole(String role) => role == 'admin' ? 'Admin' : 'Peserta';

  String _displayOrDash(String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty ? '-' : v;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          final roleLabel = _displayRole(user.role);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: _ProfileHeader(
                          name: user.name,
                          email: user.email,
                          roleLabel: roleLabel,
                          photoUrl: user.photoUrl,
                          onEdit: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Column(
                          children: [
                            _SectionCard(
                              title: 'Informasi Akun',
                              icon: Icons.badge_rounded,
                              children: [
                                _InfoTile(
                                  icon: Icons.person_rounded,
                                  label: 'Nama',
                                  value: user.name,
                                ),
                                _InfoTile(
                                  icon: Icons.email_rounded,
                                  label: 'Email',
                                  value: user.email,
                                ),
                                _InfoTile(
                                  icon: Icons.verified_user_rounded,
                                  label: 'Role',
                                  value: roleLabel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Kontak',
                              icon: Icons.call_rounded,
                              children: [
                                _InfoTile(
                                  icon: Icons.phone_rounded,
                                  label: 'Nomor Telepon',
                                  value: _displayOrDash(user.phone),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Tentang',
                              icon: Icons.info_rounded,
                              children: [
                                _InfoTile(
                                  icon: Icons.notes_rounded,
                                  label: 'Bio',
                                  value: _displayOrDash(user.bio),
                                  isMultiline: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomElevatedButton(
                              label: 'Edit Profil',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _confirmLogout(context),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Keluar'),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.photoUrl,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String roleLabel;
  final String? photoUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(photoUrl: photoUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit Profil',
                      icon: const Icon(Icons.edit_rounded),
                      color: AppColors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.90),
                  ),
                ),
                const SizedBox(height: 12),
                _RolePill(roleLabel: roleLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: ClipOval(
        child: photoUrl == null
            ? const Icon(Icons.person_rounded, color: AppColors.white, size: 34)
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: AppColors.white,
                  size: 34,
                ),
              ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final bg = roleLabel == 'Admin'
        ? AppColors.warningLight.withValues(alpha: 0.30)
        : AppColors.successLight.withValues(alpha: 0.28);

    final fg = roleLabel == 'Admin' ? AppColors.warningLight : AppColors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleLabel == 'Admin'
                ? Icons.admin_panel_settings_rounded
                : Icons.emoji_people_rounded,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            roleLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.gray200.withValues(alpha: 0.70)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.gray700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray900,
                    height: isMultiline ? 1.3 : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
