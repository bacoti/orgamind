import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../models/user.dart';

class EventService {
  // Update status presensi peserta (admin manual hadirkan)
  Future<bool> updateParticipantStatus({
    required int eventId,
    required String userId,
    required String status,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/events/$eventId/presensi');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'status': status}),
    );
    return response.statusCode == 200;
  }

  // Get daftar peserta event
  Future<List<User>> getEventParticipants(int eventId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/events/$eventId/participants');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => User.fromJson(e)).toList();
    }
    return [];
  }
}
