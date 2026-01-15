import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Base URL - Otomatis pilih berdasarkan platform
  // Android Emulator: 10.0.2.2 (alias ke host machine)
  // iOS Simulator / Web / Desktop: localhost
  // Physical Device: ganti dengan IP PC kamu
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    if (Platform.isAndroid) {
      // Android Emulator menggunakan 10.0.2.2 untuk akses localhost PC
      return 'http://10.0.2.2:3000/api';
    }
    
    // iOS, macOS, Windows, Linux
    return 'http://localhost:3000/api';
  }
  
  // Auth Endpoints
  static String get authRegister => '$baseUrl/auth/register';
  static String get authLogin => '$baseUrl/auth/login';
  static String get authForgotPassword => '$baseUrl/auth/forgot-password';
  static String get authChangePassword => '$baseUrl/auth/change-password';
  
  // User Endpoints
  static String get userProfile => '$baseUrl/users/profile';
  static String get userUpdateProfile => '$baseUrl/users/profile';
  static String get users => '$baseUrl/users';
  static String userById(String id) => '$baseUrl/users/$id';
  static String userUpdate(String id) => '$baseUrl/users/$id';
  static String userDelete(String id) => '$baseUrl/users/$id';
  static String get userCreate => '$baseUrl/users';
  
  // Event Endpoints
  static String get events => '$baseUrl/events';
  static String eventDetail(int id) => '$baseUrl/events/$id';
  static String eventUpdate(int id) => '$baseUrl/events/$id';
  static String eventDelete(int id) => '$baseUrl/events/$id';
  static String eventJoin(int id) => '$baseUrl/events/$id/join';
  static String eventLeave(int id) => '$baseUrl/events/$id/leave';
  static String get eventUserEvents => '$baseUrl/events/user/organizer';
  static String get eventUserParticipating => '$baseUrl/events/user/participant';

  // Invitation Endpoints
  static String get userInvitations => '$baseUrl/events/user/invitations';
  static String eventInvite(int id) => '$baseUrl/events/$id/invite';
  static String eventRespond(int id) => '$baseUrl/events/$id/respond';
  
  // Helper method to get authorization header
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}

