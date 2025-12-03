import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../constants/api_config.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  List<EventModel> _userEvents = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<EventModel> get events => _events;
  List<EventModel> get userEvents => _userEvents;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get All Events
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

  // Get Event Detail
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

  // Create Event
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
          // Refresh events list
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

  // Update Event
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

  // Delete Event
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

  // Join Event
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

  // Leave Event
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

  // Get User Events
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

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }
}
