// lib/screens/event_list_screen.dart
// (VERSI BERSIH - LIST KOSONG - SIAP DI-INPUT)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  // --- PERBAIKAN DI SINI: KITA KOSONGKAN LIST-NYA ---
  List<EventModel> dummyEvents = []; 
  // --------------------------------------------------

  void _tambahAcaraBaru(EventModel acaraBaru) {
    setState(() {
      dummyEvents.add(acaraBaru);
      // Urutkan tanggal (terdekat di atas)
      dummyEvents.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  void _bukaHalamanInput() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreateEventScreen(onSimpan: _tambahAcaraBaru),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Acara Ku',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      // Tampilkan pesan jika kosong, tampilkan list jika ada isinya
      body: dummyEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada acara.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  Text(
                    'Tekan tombol + untuk membuat acara baru.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dummyEvents.length,
              itemBuilder: (ctx, index) {
                final event = dummyEvents[index];
                
                // Logika warna badge status
                final isConfirmed = event.status == 'Hadir';
                final statusColor = isConfirmed ? Colors.green.shade50 : Colors.orange.shade50;
                final statusTextColor = isConfirmed ? Colors.green : Colors.orange;

                return GestureDetector(
                  onTap: () async { // Tambahkan 'async'
                    // Tunggu sampai balik dari halaman detail
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(event: event),
                      ),
                    );
                    // Setelah balik, refresh tampilan biar statusnya update
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.status,
                              style: TextStyle(
                                color: statusTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Judul
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tanggal
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy').format(event.date),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Lokasi
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                event.location,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaHalamanInput,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}