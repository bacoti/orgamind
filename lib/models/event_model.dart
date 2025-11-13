// lib/models/event_model.dart

class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String location;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
  });
}