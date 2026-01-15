import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }

  // Auth
  static String get authRegister => '$baseUrl/auth/register';
  static String get authLogin => '$baseUrl/auth/login';
  static String get authForgotPassword => '$baseUrl/auth/forgot-password';
  static String get authChangePassword => '$baseUrl/auth/change-password';

  // Users
  static String get userProfile => '$baseUrl/users/profile';
  static String get userUpdateProfile => '$baseUrl/users/profile';
  static String get users => '$baseUrl/users';
  static String userById(String id) => '$baseUrl/users/$id';
  static String userUpdate(String id) => '$baseUrl/users/$id';
  static String userDelete(String id) => '$baseUrl/users/$id';
  static String get userCreate => '$baseUrl/users';

  // Events
  static String get events => '$baseUrl/events';
  static String eventDetail(int id) => '$baseUrl/events/$id';
  static String eventUpdate(int id) => '$baseUrl/events/$id';
  static String eventDelete(int id) => '$baseUrl/events/$id';
  static String eventJoin(int id) => '$baseUrl/events/$id/join';
  static String eventLeave(int id) => '$baseUrl/events/$id/leave';
  static String get eventUserEvents => '$baseUrl/events/user/organizer';
  static String get eventUserParticipating => '$baseUrl/events/user/participant';

  // Attendance
  static String attendanceQrToken(int eventId) => '$baseUrl/attendance/qr-token/$eventId';
  static String get attendanceScan => '$baseUrl/attendance/scan';
  static String attendanceManual(int eventId) => '$baseUrl/attendance/manual/$eventId';
  static String attendanceListByEvent(int eventId) => '$baseUrl/attendance/event/$eventId';

  // Invitations
  static String get userInvitations => '$baseUrl/events/user/invitations';
  static String eventInvite(int id) => '$baseUrl/events/$id/invite';
  static String eventRespond(int id) => '$baseUrl/events/$id/respond';

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
