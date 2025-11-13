import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validasi Nama
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.nameRequired;
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  /// Validasi Email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  /// Validasi Password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Validasi Konfirmasi Password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _passwordController.text) {
      return AppStrings.passwordNotMatch;
    }
    return null;
  }

  /// Handle Register
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      LoadingDialog.show(context, message: AppStrings.loading);

      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (mounted) {
        LoadingDialog.hide(context);

        if (success) {
          CustomAlertDialog.show(
            context,
            title: AppStrings.success,
            message: AppStrings.registerSuccess,
            actionLabel: AppStrings.ok,
            onAction: () {
              Navigator.pop(context); // Close dialog
            },
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.registerSuccess)),
              );
            }
          });
        } else {
          CustomAlertDialog.show(
            context,
            title: AppStrings.error,
            message: authProvider.errorMessage ?? 'Registrasi gagal',
            actionLabel: AppStrings.ok,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                AppStrings.register,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Buat akun baru untuk memulai!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray600,
                    ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
                    CustomTextField(
                      label: AppStrings.fullName,
                      hint: 'Nama Lengkap Anda',
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      validator: _validateName,
                      prefixIcon: const Icon(Icons.person_outline),
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
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    CustomTextField(
                      label: AppStrings.password,
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    CustomTextField(
                      label: AppStrings.confirmPassword,
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Register Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return CustomElevatedButton(
                          label: AppStrings.register,
                          onPressed: _handleRegister,
                          isLoading: authProvider.isLoading,
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.alreadyHaveAccount,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppStrings.login,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
