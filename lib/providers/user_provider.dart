// lib/providers/user_provider.dart
// State management for user management (admin)

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../constants/api_config.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final AuthService _authService = AuthService();

  // Get All Users
  Future<bool> getAllUsers({String? role, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.init();
      final token = _authService.getToken();

      if (token == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Build query parameters
      String url = ApiConfig.users;
      final queryParams = <String, String>{};
      
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> usersData = data['data'];
          _users = usersData.map((json) => User.fromJson(json)).toList();
          notifyListeners();
          return true;
        }
      }

      _errorMessage = 'Failed to load users';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // Get User by ID
  Future<User?> getUserById(String id) async {
    try {
      await _authService.init();
      final token = _authService.getToken();

      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.userById(id)),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return null;
    }
  }

  // Create User
  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'participant',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.init();
      final token = _authService.getToken();

      if (token == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.userCreate),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // User created successfully
          notifyListeners();
          return true;
        }
      }

      final data = jsonDecode(response.body);
      _errorMessage = data['message'] ?? 'Failed to create user';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // Update User
  Future<bool> updateUser({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? bio,
    String? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.init();
      final token = _authService.getToken();

      if (token == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.put(
        Uri.parse(ApiConfig.userUpdate(id)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'bio': bio,
          'role': role,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // User updated successfully
          notifyListeners();
          return true;
        }
      }

      final data = jsonDecode(response.body);
      _errorMessage = data['message'] ?? 'Failed to update user';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete User
  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.init();
      final token = _authService.getToken();

      if (token == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.userDelete(id)),
        headers: ApiConfig.getHeaders(token: token),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Remove from local list
          _users.removeWhere((user) => user.id == id);
          notifyListeners();
          return true;
        }
      }

      _errorMessage = 'Failed to delete user';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
