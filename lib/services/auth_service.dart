import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

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
      // Simulasi API call (replace dengan API sesungguhnya)
      await Future.delayed(const Duration(seconds: 2));

      // Validasi dummy (ganti dengan API validation)
      if (email.isNotEmpty && password.isNotEmpty) {
        // Generate dummy token
        final String token =
            'dummy_token_${DateTime.now().millisecondsSinceEpoch}';

        // Cari user yang sudah terdaftar berdasarkan email
        String? registeredName = _getUserNameFromStorage(email);
        
        // Jika user sudah pernah register, gunakan nama tersebut
        // Jika belum pernah register, extract nama dari email
        final String nameToUse = registeredName ?? 
            email.split('@')[0].replaceAll('.', ' ').toUpperCase();

        // Create dummy user
        final User user = User(
          id: 'user_001',
          name: nameToUse,
          email: email,
          phone: '08123456789',
          role: role,
        );

        // Save token dan user data
        await _prefs.setString(_tokenKey, token);
        await _prefs.setString(_userKey, _userToJsonString(user));

        return true;
      }
      return false;
    } catch (e) {
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

      // Simulasi API call
      await Future.delayed(const Duration(seconds: 2));

      if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
        // Generate dummy token
        final String token =
            'dummy_token_${DateTime.now().millisecondsSinceEpoch}';

        // Create user
        final User user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          email: email,
          role: role,
        );

        // Save token dan user data
        await _prefs.setString(_tokenKey, token);
        await _prefs.setString(_userKey, _userToJsonString(user));
        
        // Simpan mapping email ke nama untuk digunakan saat login nanti
        await _prefs.setString('user_name_$email', name);

        return true;
      }
      return false;
    } catch (e) {
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
      await Future.delayed(const Duration(seconds: 1));
      await _prefs.setString(_userKey, _userToJsonString(user));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  // Helper: Get registered user name by email from storage
  String? _getUserNameFromStorage(String email) {
    try {
      // Cari di semua SharedPreferences keys yang mengandung user data
      // Gunakan key format: 'user_email_data' untuk menyimpan mapping email ke nama
      final String? storedName = _prefs.getString('user_name_$email');
      return storedName;
    } catch (e) {
      return null;
    }
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
        id: parts.length > 0 ? parts[0] : '',
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
