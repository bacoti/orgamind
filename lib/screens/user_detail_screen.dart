import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../constants/theme.dart';

class UserDetailScreen extends StatefulWidget {
  final User? user;

  const UserDetailScreen({super.key, this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes for better navigation
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'participant';
  User? _user;

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Track field completion for progress indicator
  int get _completedFields {
    int count = 0;
    if (_nameController.text.isNotEmpty) count++;
    if (_emailController.text.isNotEmpty) count++;
    if (_phoneController.text.isNotEmpty) count++;
    if (widget.user == null) {
      if (_passwordController.text.isNotEmpty) count++;
      if (_confirmPasswordController.text.isNotEmpty) count++;
    }
    return count;
  }

  int get _totalRequiredFields => widget.user == null ? 5 : 2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.user != null) {
      _user = widget.user;
      _nameController.text = _user?.name ?? '';
      _emailController.text = _user?.email ?? '';
      _phoneController.text = _user?.phone ?? '';
      _bioController.text = _user?.bio ?? '';
      _selectedRole = _user?.role ?? 'participant';
      _isLoading = false;
    } else {
      _isLoading = false;
      _isEditing = true;
    }

    _animationController.forward();

    // Add listeners for real-time validation feedback
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {}); // Rebuild to update progress indicator
  }

  Future<void> _loadUserData() async {
    if (widget.user == null) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.getUserById(widget.user!.id);

    if (userProvider.errorMessage == null && userProvider.users.isNotEmpty) {
      _user = userProvider.users.firstWhere(
        (u) => u.id == widget.user!.id,
        orElse: () => widget.user!,
      );

      _nameController.text = _user?.name ?? '';
      _emailController.text = _user?.email ?? '';
      _phoneController.text = _user?.phone ?? '';
      _bioController.text = _user?.bio ?? '';
      _selectedRole = _user?.role ?? 'participant';
    }

    setState(() => _isLoading = false);
  }

  // Email validation with proper regex
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Phone validation
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (widget.user != null) return null; // Password not required for edit
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  // Confirm password validation
  String? _validateConfirmPassword(String? value) {
    if (widget.user != null) return null;
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != _passwordController.text) {
      return 'Password tidak cocok';
    }
    return null;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      // Shake animation or vibration feedback for error
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Mohon lengkapi semua field yang wajib diisi'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Show confirmation dialog before saving
    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isSaving = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    bool success;
    if (widget.user == null) {
      // Create new user
      success = await userProvider.createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: _selectedRole,
      );
    } else {
      // Update existing user
      success = await userProvider.updateUser(
        id: widget.user!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        role: _selectedRole,
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.user == null
                      ? 'User berhasil ditambahkan!'
                      : 'Perubahan berhasil disimpan!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (widget.user == null) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isEditing = false);
        _loadUserData();
      }
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(userProvider.errorMessage ?? 'Gagal menyimpan data'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: _saveChanges,
          ),
        ),
      );
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.user == null ? Icons.person_add : Icons.save,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.user == null ? 'Tambah User' : 'Simpan Perubahan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user == null
                  ? 'Apakah Anda yakin ingin menambahkan user baru dengan data berikut?'
                  : 'Apakah Anda yakin ingin menyimpan perubahan?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            _buildConfirmationItem(Icons.person, 'Nama', _nameController.text),
            _buildConfirmationItem(Icons.email, 'Email', _emailController.text),
            if (_phoneController.text.isNotEmpty)
              _buildConfirmationItem(
                  Icons.phone, 'Telepon', _phoneController.text),
            _buildConfirmationItem(
              Icons.admin_panel_settings,
              'Role',
              _selectedRole == 'admin' ? 'Administrator' : 'Participant',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(widget.user == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    if (widget.user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Hapus User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange[700]),
            const SizedBox(height: 16),
            Text(
              'Apakah Anda yakin ingin menghapus "${_user?.name ?? 'user ini'}"?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindakan ini tidak dapat dibatalkan!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.deleteUser(widget.user!.id);
      setState(() => _isSaving = false);

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('User berhasil dihapus')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      Text(userProvider.errorMessage ?? 'Gagal menghapus user'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // Handle back button with unsaved changes warning
  Future<bool> _onWillPop() async {
    if (!_isEditing) return true;

    final hasChanges = _nameController.text != (_user?.name ?? '') ||
        _emailController.text != (_user?.email ?? '') ||
        _phoneController.text != (_user?.phone ?? '') ||
        _bioController.text != (_user?.bio ?? '') ||
        _selectedRole != (_user?.role ?? 'participant');

    if (!hasChanges && widget.user != null) return true;
    if (widget.user == null &&
        _nameController.text.isEmpty &&
        _emailController.text.isEmpty &&
        _passwordController.text.isEmpty) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Perubahan Belum Disimpan'),
          ],
        ),
        content: const Text(
          'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Tetap di Sini',
                style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _bioFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAddMode = widget.user == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomScrollView(
                      slivers: [
                        _buildAppBar(isAddMode),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Progress Indicator for Add Mode
                                  if (isAddMode) ...[
                                    _buildProgressIndicator(),
                                    const SizedBox(height: 24),
                                  ],

                                  // Section Header - Personal Information
                                  _buildSectionHeader(
                                    'Informasi Pribadi',
                                    Icons.person_outline,
                                    'Data dasar pengguna',
                                  ),
                                  const SizedBox(height: 16),

                                  // Name Field
                                  _buildInputField(
                                    controller: _nameController,
                                    focusNode: _nameFocus,
                                    nextFocus: _emailFocus,
                                    label: 'Nama Lengkap',
                                    hint: 'Masukkan nama lengkap',
                                    icon: Icons.person,
                                    isRequired: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nama wajib diisi';
                                      }
                                      if (value.length < 3) {
                                        return 'Nama minimal 3 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Email Field
                                  _buildInputField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    nextFocus: _phoneFocus,
                                    label: 'Email',
                                    hint: 'contoh@email.com',
                                    icon: Icons.email_outlined,
                                    isRequired: true,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 16),

                                  // Phone Field
                                  _buildInputField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    nextFocus:
                                        isAddMode ? _passwordFocus : _bioFocus,
                                    label: 'Nomor Telepon',
                                    hint: '+62 812 3456 7890',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: _validatePhone,
                                    helperText: 'Opsional - untuk notifikasi',
                                  ),
                                  const SizedBox(height: 24),

                                  // Password Section (only for Add Mode)
                                  if (isAddMode) ...[
                                    _buildSectionHeader(
                                      'Keamanan Akun',
                                      Icons.security,
                                      'Buat password yang kuat',
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Field
                                    _buildPasswordField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      nextFocus: _confirmPasswordFocus,
                                      label: 'Password',
                                      hint: 'Minimal 6 karakter',
                                      obscureText: _obscurePassword,
                                      onToggleVisibility: () {
                                        setState(() =>
                                            _obscurePassword = !_obscurePassword);
                                      },
                                      validator: _validatePassword,
                                    ),
                                    const SizedBox(height: 16),

                                    // Confirm Password Field
                                    _buildPasswordField(
                                      controller: _confirmPasswordController,
                                      focusNode: _confirmPasswordFocus,
                                      nextFocus: null,
                                      label: 'Konfirmasi Password',
                                      hint: 'Masukkan password yang sama',
                                      obscureText: _obscureConfirmPassword,
                                      onToggleVisibility: () {
                                        setState(() =>
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword);
                                      },
                                      validator: _validateConfirmPassword,
                                    ),

                                    // Password strength indicator
                                    if (_passwordController.text.isNotEmpty)
                                      _buildPasswordStrengthIndicator(),

                                    const SizedBox(height: 24),
                                  ],

                                  // Bio Section (only for Edit Mode)
                                  if (!isAddMode) ...[
                                    _buildSectionHeader(
                                      'Bio',
                                      Icons.info_outline,
                                      'Ceritakan tentang diri Anda',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      controller: _bioController,
                                      focusNode: _bioFocus,
                                      label: 'Bio',
                                      hint: 'Tulis bio singkat...',
                                      icon: Icons.edit_note,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Role Section
                                  _buildSectionHeader(
                                    'Role & Hak Akses',
                                    Icons.admin_panel_settings_outlined,
                                    'Tentukan level akses pengguna',
                                  ),
                                  const SizedBox(height: 16),

                                  // Role Selector Cards
                                  if (_isEditing) _buildRoleSelector(),
                                  if (!_isEditing) _buildRoleBadge(),

                                  const SizedBox(height: 24),

                                  // Account Info Card (only for Edit Mode)
                                  if (!isAddMode) ...[
                                    _buildAccountInfoCard(),
                                    const SizedBox(height: 24),
                                  ],

                                  // Action Buttons
                                  if (_isEditing) ...[
                                    _buildActionButtons(isAddMode),
                                    const SizedBox(height: 32),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

            // Loading Overlay
            if (_isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            isAddMode
                                ? 'Menambahkan user...'
                                : 'Menyimpan perubahan...',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isAddMode) {
    return SliverAppBar(
      expandedHeight: isAddMode ? 180 : 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.of(context).pop();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isAddMode ? 'Tambah User Baru' : (_user?.name ?? 'Detail User'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(128, 0, 0, 0),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'user_avatar_${_user?.id ?? 'new'}',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: _user?.photoUrl != null
                            ? NetworkImage(_user!.photoUrl!)
                            : null,
                        child: _user?.photoUrl == null
                            ? Icon(
                                isAddMode ? Icons.person_add : Icons.person,
                                size: 40,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (isAddMode) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Isi form di bawah ini',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (!_isEditing && !isAddMode)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            tooltip: 'Edit User',
            onPressed: () => setState(() => _isEditing = true),
          ),
        if (_isEditing && !isAddMode)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
            tooltip: 'Batal Edit',
            onPressed: () {
              setState(() => _isEditing = false);
              _loadUserData();
            },
          ),
        if (!isAddMode)
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteUser();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.delete, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Hapus User'),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _completedFields / _totalRequiredFields;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Pengisian',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '$_completedFields/$_totalRequiredFields field',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : AppColors.primary,
              ),
            ),
          ),
          if (progress == 1.0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Semua field wajib sudah terisi!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? helperText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: _isEditing,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon:
            Icon(icon, color: _isEditing ? AppColors.primary : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocus,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hint,
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
          tooltip: obscureText ? 'Tampilkan password' : 'Sembunyikan password',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    int strength = 0;
    String strengthText = 'Sangat Lemah';
    Color strengthColor = Colors.red;

    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    switch (strength) {
      case 1:
        strengthText = 'Lemah';
        strengthColor = Colors.red;
        break;
      case 2:
        strengthText = 'Cukup';
        strengthColor = Colors.orange;
        break;
      case 3:
        strengthText = 'Sedang';
        strengthColor = Colors.yellow[700]!;
        break;
      case 4:
        strengthText = 'Kuat';
        strengthColor = Colors.lightGreen;
        break;
      case 5:
        strengthText = 'Sangat Kuat';
        strengthColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Kekuatan Password: ',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color:
                        index < strength ? strengthColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildPasswordHint('6+ karakter', password.length >= 6),
              _buildPasswordHint(
                  'Huruf besar', password.contains(RegExp(r'[A-Z]'))),
              _buildPasswordHint('Angka', password.contains(RegExp(r'[0-9]'))),
              _buildPasswordHint('Simbol',
                  password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordHint(String text, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: isMet ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isMet ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            'participant',
            'Participant',
            'Akses terbatas untuk pengguna biasa',
            Icons.person,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleCard(
            'admin',
            'Administrator',
            'Akses penuh ke semua fitur',
            Icons.admin_panel_settings,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    String role,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected ? color.withValues(alpha: 0.2) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    final isAdmin = _selectedRole == 'admin';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.orange : Colors.blue,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAdmin
                  ? Colors.orange.withValues(alpha: 0.2)
                  : Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin ? Colors.orange : Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Administrator' : 'Participant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAdmin ? Colors.orange[800] : Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin
                      ? 'Memiliki akses penuh ke semua fitur'
                      : 'Akses terbatas untuk pengguna biasa',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline,
                      color: Colors.grey[600], size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('User ID', _user?.id ?? '-', Icons.badge),
            const Divider(height: 24),
            _buildInfoRow(
                'Dibuat pada', 'Tidak tersedia', Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isAddMode) {
    return Column(
      children: [
        // Primary Save Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isAddMode ? Icons.person_add : Icons.save),
                const SizedBox(width: 12),
                Text(
                  isAddMode ? 'Tambah User' : 'Simpan Perubahan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Cancel Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    final shouldPop = await _onWillPop();
                    if (shouldPop && mounted) Navigator.of(context).pop();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: Colors.grey[400]),
            tooltip: 'Salin',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label disalin ke clipboard'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
