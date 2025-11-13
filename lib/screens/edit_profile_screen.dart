import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late FocusNode _nameFocus;
  late FocusNode _emailFocus;
  late FocusNode _phoneFocus;
  late FocusNode _bioFocus;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');

    _nameFocus = FocusNode();
    _emailFocus = FocusNode();
    _phoneFocus = FocusNode();
    _bioFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  /// Validasi Nama
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }

  /// Validasi Email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  /// Validasi Phone
  String? _validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Format nomor telepon tidak valid';
      }
    }
    return null;
  }

  /// Handle Update Profile
  Future<void> _handleUpdateProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) return;

      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      LoadingDialog.show(context, message: 'Memperbarui profil...');

      final success = await authProvider.updateProfile(updatedUser);

      if (mounted) {
        LoadingDialog.hide(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui')),
          );
          Navigator.of(context).pop(); // Kembali ke profile screen
        } else {
          CustomAlertDialog.show(
            context,
            title: AppStrings.error,
            message: authProvider.errorMessage ?? 'Gagal memperbarui profil',
            actionLabel: AppStrings.ok,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              const SizedBox(height: 16),
              Text(
                'Perbarui informasi akun Anda',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.gray600),
              ),
              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name Field
                    CustomTextField(
                      label: 'Nama',
                      hint: 'Masukkan nama lengkap',
                      controller: _nameController,
                      validator: _validateName,
                      prefixIcon: const Icon(Icons.person_outlined),
                      focusNode: _nameFocus,
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    CustomTextField(
                      label: AppStrings.email,
                      hint: 'contoh@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                      focusNode: _emailFocus,
                    ),
                    const SizedBox(height: 20),

                    // Phone Field
                    CustomTextField(
                      label: 'Nomor Telepon',
                      hint: '+6281234567890',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      focusNode: _phoneFocus,
                    ),
                    const SizedBox(height: 20),

                    // Bio Field
                    CustomTextField(
                      label: 'Bio',
                      hint: 'Ceritakan sedikit tentang diri Anda',
                      controller: _bioController,
                      maxLines: 3,
                      focusNode: _bioFocus,
                    ),
                    const SizedBox(height: 24),

                    // Update Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return CustomElevatedButton(
                          label: 'Simpan Perubahan',
                          onPressed: _handleUpdateProfile,
                          isLoading: authProvider.isLoading,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
