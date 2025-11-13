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
  Future<bool> login(String email, String password) async {
    try {
      // Simulasi API call (replace dengan API sesungguhnya)
      await Future.delayed(const Duration(seconds: 2));

      // Validasi dummy (ganti dengan API validation)
      if (email.isNotEmpty && password.isNotEmpty) {
        // Generate dummy token
        final String token =
            'dummy_token_${DateTime.now().millisecondsSinceEpoch}';

        // Create dummy user
        final User user = User(
          id: 'user_001',
          name: 'John Doe',
          email: email,
          phone: '08123456789',
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
    String confirmPassword,
  ) async {
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

  // Helper: Convert User to JSON string
  String _userToJsonString(User user) {
    // Simple JSON encoding (bisa menggunakan json_serializable untuk production)
    return '${user.id}|${user.name}|${user.email}|${user.phone}|${user.photoUrl}|${user.bio}';
  }

  // Helper: Parse User from JSON string
  User _userFromJsonString(String jsonString) {
    final parts = jsonString.split('|');
    return User(
      id: parts[0],
      name: parts[1],
      email: parts[2],
      phone: parts[3].isEmpty ? null : parts[3],
      photoUrl: parts[4].isEmpty ? null : parts[4],
      bio: parts[5].isEmpty ? null : parts[5],
    );
  }
}
