// lib/providers/event_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../constants/api_config.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  List<EventModel> _userEvents = [];
  List<EventModel> _invitations = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  List<EventModel> get userEvents => _userEvents;
  List<EventModel> get invitations => _invitations;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> getAllEvents({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.events),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _events = (data['data'] as List)
              .map((event) => EventModel.fromJson(event))
              .toList();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Failed to load events';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> getEventDetail(int eventId, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.eventDetail(eventId)),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _selectedEvent = EventModel.fromJson(data['data']);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Failed to load event detail';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createEvent({
    required String token,
    required String title,
    required String description,
    required String location,
    required String date,
    required String time,
    required String category,
    required int capacity,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.events),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'date': date,
          'time': time,
          'category': category,
          'capacity': capacity,
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await getAllEvents(token: token);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Failed to create event';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent({
    required String token,
    required int eventId,
    required String title,
    required String description,
    required String location,
    required String date,
    required String time,
    required String category,
    required int capacity,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.eventUpdate(eventId)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'date': date,
          'time': time,
          'category': category,
          'capacity': capacity,
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await getAllEvents(token: token);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Failed to update event';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(int eventId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.eventDelete(eventId)),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await getAllEvents(token: token);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Failed to delete event';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinEvent(int eventId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eventJoin(eventId)),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await getAllEvents(token: token);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Failed to join event';
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveEvent(int eventId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.eventLeave(eventId)),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await getAllEvents(token: token);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Failed to leave event';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> getUserEvents(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.eventUserEvents),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _userEvents = (data['data'] as List)
              .map((event) => EventModel.fromJson(event))
              .toList();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Failed to load your events';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> inviteParticipants(String eventId, List<int> userIds, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = int.tryParse(eventId) ?? 0;

      final response = await http.post(
        Uri.parse(ApiConfig.eventInvite(id)), 
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'userIds': userIds,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Gagal mengundang peserta';
        }
      } else {
        _errorMessage = data['message'] ?? 'Gagal menghubungi server';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> getUserInvitations(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userInvitations),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _invitations = (data['data'] as List)
              .map((event) => EventModel.fromJson(event))
              .toList();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = 'Gagal memuat undangan';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondToInvitation(int eventId, String action, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eventRespond(eventId)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({'action': action}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _invitations.removeWhere((e) => e.id == eventId); 
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 12. NEW: Get Event Participants
  Future<List<dynamic>> getEventParticipants(int eventId, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/events/$eventId/participants');
      print('Fetching participants from: $url'); 

      final response = await http.get(
        url,
        headers: ApiConfig.getHeaders(token: token),
      );

      print('Response status: ${response.statusCode}'); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Error fetching participants: $e'); 
      return [];
    }
  }

  // 13. NEW: Admin Update Status
  Future<bool> updateParticipantStatus(int eventId, String userId, String status, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId/participants/$userId'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error updating status: $e");
      return false;
    }
  }

  // 14. NEW: Admin Remove Participant
  Future<bool> removeParticipant(int eventId, String userId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId/participants/$userId'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error removing participant: $e");
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }
}