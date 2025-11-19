// lib/screens/event_detail_screen.dart
// (VERSI UPDATE - TOMBOL HADIR/TOLAK SUDAH BERFUNGSI)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.event.status; // Ambil status awal
  }

  // Fungsi update status
  void _updateStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
      widget.event.status = newStatus; // Update data asli
    });

    // Pesan Pop-up beda-beda tergantung pilihan
    String title = newStatus == 'Hadir' ? 'Berhasil!' : 'Dibatalkan';
    String content = newStatus == 'Hadir' 
        ? 'Kehadiran Anda telah dikonfirmasi. Sampai jumpa!' 
        : 'Anda telah menolak undangan ini.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup Dialog
              Navigator.pop(context, true); // Kembali ke List & Refresh
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Acara',
          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder Gambar
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.blue.shade50,
                    child: Icon(Icons.image, size: 80, color: Colors.blue.shade200),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildInfoRow(Icons.calendar_today, DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(widget.event.date)),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.access_time, widget.event.time),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on, widget.event.location),
                        
                        // --- STATUS SAAT INI (BARU) ---
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor(_currentStatus)),
                          ),
                          child: Text(
                            'Status: $_currentStatus',
                            style: TextStyle(
                              color: _getStatusColor(_currentStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // -----------------------------

                        const SizedBox(height: 30),
                        const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.event.description, style: TextStyle(color: Colors.grey[600], height: 1.5)),

                        const SizedBox(height: 30),
                        const Text('Pembicara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(radius: 25, backgroundColor: Colors.grey[300]),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.event.speakerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(widget.event.speakerRole, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                // TOMBOL TOLAK
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus('Ditolak'), // Panggil fungsi tolak
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 16),
                // TOMBOL HADIR
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('Hadir'), // Panggil fungsi hadir
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Hadir', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk warna status
  Color _getStatusColor(String status) {
    if (status == 'Hadir') return Colors.green;
    if (status == 'Ditolak') return Colors.red;
    return Colors.orange;
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
      ],
    );
  }
}