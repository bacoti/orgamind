// lib/constants/api_config.dart

class ApiConfig {
  // Base URL - Ganti sesuai environment
  // Untuk Android Emulator gunakan: http://10.0.2.2:3000/api
  // Untuk iOS Simulator gunakan: http://localhost:3000/api
  // Untuk Physical Device / Chrome gunakan: http://localhost:3000/api
  static const String baseUrl = 'http://localhost:3000/api'; 
  
  // Auth Endpoints
  static const String authRegister = '$baseUrl/auth/register';
  static const String authLogin = '$baseUrl/auth/login';
  static const String authForgotPassword = '$baseUrl/auth/forgot-password';
  static const String authChangePassword = '$baseUrl/auth/change-password';
  
  // User Endpoints
  static const String userProfile = '$baseUrl/users/profile';
  static const String userUpdateProfile = '$baseUrl/users/profile';
  static const String users = '$baseUrl/users';
  static String userById(String id) => '$baseUrl/users/$id';
  static String userUpdate(String id) => '$baseUrl/users/$id';
  static String userDelete(String id) => '$baseUrl/users/$id';
  static const String userCreate = '$baseUrl/users';
  
  // Event Endpoints
  static const String events = '$baseUrl/events';
  static String eventDetail(int id) => '$baseUrl/events/$id';
  static String eventUpdate(int id) => '$baseUrl/events/$id';
  static String eventDelete(int id) => '$baseUrl/events/$id';
  static String eventJoin(int id) => '$baseUrl/events/$id/join';
  static String eventLeave(int id) => '$baseUrl/events/$id/leave';
  static const String eventUserEvents = '$baseUrl/events/user/organizer';
  static const String eventUserParticipating = '$baseUrl/events/user/participant';
  
  // --- FITUR UNDANGAN (YANG TADI HILANG) ---
  static const String userInvitations = '$baseUrl/events/user/invitations';
  static String eventInvite(int id) => '$baseUrl/events/$id/invite';
  
  // INI YANG MENYEBABKAN ERROR (Tadi belum ada):
  static String eventRespond(int id) => '$baseUrl/events/$id/respond';
  // -----------------------------------------

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