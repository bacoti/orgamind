// lib/models/event_model.dart

class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  String status; // Hapus kata 'final' (BENAR, jadi bisa diubah)
  final String time;   // Baru: "10:00 - 14:00 WIB"
  final String description; // Baru
  final String speakerName; // Baru
  final String speakerRole; // Baru

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    this.status = 'Menunggu Konfirmasi', // Default status
    this.time = '09:00 - 12:00 WIB',
    this.description = 'Deskripsi acara belum ditambahkan.',
    this.speakerName = 'Panitia',
    this.speakerRole = 'Organizer',
  });
}