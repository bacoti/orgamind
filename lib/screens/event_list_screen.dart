// lib/screens/event_list_screen.dart
// (KODE BERSIH - TANPA MIXIN YANG GAGAL)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventListScreen extends StatefulWidget {
  EventListScreen({Key? key}) : super(key: key);

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

// 'with AutomaticKeep...' SUDAH DIHAPUS, karena tidak perlu
class _EventListScreenState extends State<EventListScreen> {
  List<EventModel> dummyEvents = [];

  // 'wantKeepAlive' SUDAH DIHAPUS

  void _tambahAcaraBaru(EventModel acaraBaru) {
    setState(() {
      dummyEvents.add(acaraBaru);
    });
  }

  void _bukaHalamanInput() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreateEventScreen(
          onSimpan: _tambahAcaraBaru,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 'super.build(context)' SUDAH DIHAPUS

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Acara ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: dummyEvents.isEmpty
          ? Center(
              child: Text(
                'Belum ada acara.\nSilakan tekan tombol + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              itemCount: dummyEvents.length,
              itemBuilder: (ctx, index) {
                final event = dummyEvents[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 25,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd').format(event.date),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                          Text(
                            DateFormat('MMM', 'id_ID').format(event.date),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(event.location),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(
                            event: event,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaHalamanInput,
        child: const Icon(Icons.add),
        tooltip: 'Input Acara Baru',
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}