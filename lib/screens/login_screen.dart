import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
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

  /// Handle Login
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      LoadingDialog.show(context, message: AppStrings.loading);

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        LoadingDialog.hide(context);

        if (success) {
          // Navigate to home screen
          // Akan dihandle oleh navigation logic di main.dart
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.loginSuccess)),
          );
        } else {
          CustomAlertDialog.show(
            context,
            title: AppStrings.error,
            message:
                authProvider.errorMessage ?? 'Gagal melakukan login',
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Text(
                AppStrings.login,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selamat kembali! Masuk ke akun Anda untuk melanjutkan',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray600,
                    ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    CustomTextField(
                      label: AppStrings.email,
                      hint: 'contoh@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                      focusNode: _emailFocus,
                      onChanged: (value) {
                        setState(() {});
                      },
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
                      focusNode: _passwordFocus,
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Navigate to forgot password screen
                        },
                        child: Text(
                          AppStrings.forgotPassword,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return CustomElevatedButton(
                          label: AppStrings.login,
                          onPressed: _handleLogin,
                          isLoading: authProvider.isLoading,
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.08),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.gray300,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'atau',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.gray300,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.dontHaveAccount,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppStrings.register,
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
