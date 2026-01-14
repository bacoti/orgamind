// lib/models/event_model.dart

class EventModel {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String time;
  final String? endTime; // <--- FIELD BARU
  final String? category;
  final String? imageUrl;
  final int capacity;
  final String? organizerName;
  final int? participantsCount;
  String? status;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    this.endTime, // <--- Add here
    this.category,
    this.imageUrl,
    this.capacity = 100,
    this.organizerName,
    this.participantsCount,
    this.status,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '09:00:00',
      endTime: json['end_time'], // <--- BACA 'end_time' DARI JSON BACKEND
      category: json['category'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      capacity: json['capacity'] ?? 100,
      organizerName: json['organizer_name'] ?? json['organizerName'],
      participantsCount:
          json['participants_count'] ?? json['participantsCount'] ?? 0,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'endTime': endTime, // <--- Sertakan saat serialisasi
      'category': category,
      'imageUrl': imageUrl,
      'capacity': capacity,
    };
  }

  String get speakerName => organizerName ?? 'Panitia';
  String get speakerRole => 'Organizer';
}
