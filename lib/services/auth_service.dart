import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../constants/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  late SharedPreferences _prefs;

  // Initialize shared preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Login endpoint
  Future<bool> login(String email, String password, {String role = 'participant'}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authLogin),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final token = data['data']['token'];
          final userData = data['data'];
          
          final User user = User(
            id: userData['userId'].toString(),
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
            photoUrl: userData['photoUrl'],
            bio: userData['bio'],
            role: userData['role'],
          );

          // Save token dan user data
          await _prefs.setString(_tokenKey, token);
          await _prefs.setString(_userKey, _userToJsonString(user));

          return true;
        }
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
      return false;
    }
  }

  // Register endpoint
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword, {String role = 'participant'}) async {
    try {
      // Validasi password
      if (password != confirmPassword) {
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.authRegister),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final token = data['data']['token'];
          final userData = data['data'];
          
          final User user = User(
            id: userData['userId'].toString(),
            name: userData['name'],
            email: userData['email'],
            role: 'participant',
          );

          // Save token dan user data
          await _prefs.setString(_tokenKey, token);
          await _prefs.setString(_userKey, _userToJsonString(user));

          return true;
        }
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Register error: $e');
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final String? userJson = _prefs.getString(_userKey);
      if (userJson != null) {
        return _userFromJsonString(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get token
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _prefs.containsKey(_tokenKey);
  }

  // Update user profile
  Future<bool> updateProfile(User user) async {
    try {
      final token = getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse(ApiConfig.userUpdateProfile),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'name': user.name,
          'phone': user.phone,
          'bio': user.bio,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final userData = data['data'];
          
          final updatedUser = User(
            id: userData['userId'].toString(),
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
            photoUrl: userData['photoUrl'],
            bio: userData['bio'],
            role: userData['role'],
          );
          
          await _prefs.setString(_userKey, _userToJsonString(updatedUser));
          return true;
        }
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Update profile error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  // Helper: Convert User to JSON string
  String _userToJsonString(User user) {
    return jsonEncode(user.toJson());
  }

  // Helper: Parse User from JSON string
  User _userFromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return User.fromJson(jsonMap);
    } catch (e) {
      // If parsing fails, try to support legacy pipe-delimited format
      final parts = jsonString.split('|');
      return User(
        id: parts.isNotEmpty ? parts[0] : '',
        name: parts.length > 1 ? parts[1] : '',
        email: parts.length > 2 ? parts[2] : '',
        phone: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
        photoUrl: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
        bio: parts.length > 5 && parts[5].isNotEmpty ? parts[5] : null,
        role: parts.length > 6 && parts[6].isNotEmpty ? parts[6] : 'participant',
      );
    }
  }
}
