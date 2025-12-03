import 'package:flutter/material.dart';
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

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = true;
  String _selectedRole = 'participant';
  User? _user;

  @override
  void initState() {
    super.initState();
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    bool success;
    if (widget.user == null) {
      // Create new user
      success = await userProvider.createUser(
        name: _nameController.text,
        email: _emailController.text,
        password: 'password123', // Default password
        phone: _phoneController.text,
        role: _selectedRole,
      );
    } else {
      // Update existing user
      success = await userProvider.updateUser(
        id: widget.user!.id,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        bio: _bioController.text,
        role: _selectedRole,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.user == null ? 'User created successfully' : 'User updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.user == null) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isEditing = false);
        _loadUserData();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? 'Failed to update user'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteUser() async {
    if (widget.user == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${_user?.name ?? 'this user'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.deleteUser(widget.user!.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.errorMessage ?? 'Failed to delete user'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.user == null ? 'Add User' : (_user?.name ?? 'User Detail'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _user?.photoUrl != null
                              ? NetworkImage(_user!.photoUrl!)
                              : null,
                          child: _user?.photoUrl == null
                              ? Text(
                                  _user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (!_isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _loadUserData();
                        },
                      ),
                    if (widget.user != null)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteUser();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete User'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role Badge
                          Center(
                            child: Chip(
                              avatar: Icon(
                                _selectedRole == 'admin'
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                _selectedRole.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: _selectedRole == 'admin'
                                  ? Colors.orange
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: !_isEditing,
                              fillColor: _isEditing ? null : Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: !_isEditing,
                              fillColor: _isEditing ? null : Colors.grey[100],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: !_isEditing,
                              fillColor: _isEditing ? null : Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bio Field
                          TextFormField(
                            controller: _bioController,
                            enabled: _isEditing,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              prefixIcon: const Icon(Icons.info),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: !_isEditing,
                              fillColor: _isEditing ? null : Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Role Selector
                          if (_isEditing)
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                prefixIcon: const Icon(Icons.admin_panel_settings),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Admin'),
                                ),
                                DropdownMenuItem(
                                  value: 'participant',
                                  child: Text('Participant'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedRole = value);
                                }
                              },
                            ),
                          const SizedBox(height: 24),

                          // Account Info
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Account Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    'User ID',
                                    _user?.id ?? '-',
                                    Icons.badge,
                                  ),
                                  if (widget.user == null)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Default password: password123',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save Button
                          if (_isEditing)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _saveChanges,
                                icon: const Icon(Icons.save),
                                label: Text(widget.user == null ? 'Create User' : 'Save Changes'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
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
                const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}
