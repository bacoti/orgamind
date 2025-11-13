// lib/screens/event_detail_screen.dart
// (KODE LENGKAP - SUDAH DIGABUNG DENGAN POP-UP)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart'; // Kita pakai model yang sama

class EventDetailScreen extends StatelessWidget {
  // Kita buat variabel untuk menampung data event yang dikirim
  final EventModel event;

  // Wajibkan 'event' saat memanggil halaman ini
  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Acara'), // Judul halaman
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. JUDUL ACARA
            Text(
              event.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 2. DETAIL TANGGAL
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Text(
                  // Format tanggal lebih lengkap (cth: Sabtu, 20 Des 2025)
                  DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(event.date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. DETAIL LOKASI
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Text(
                  event.location,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),

            const Spacer(), // Mendorong tombol ke bawah

            // 4. TOMBOL KONFIRMASI (Fitur ke-3 Anda!)
            ElevatedButton(
              // --- (INI LOGIKA YANG BARU DIGABUNG) ---
              onPressed: () {
                // Tampilkan pop-up konfirmasi (AlertDialog)
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Berhasil'),
                    content: const Text(
                        'Anda telah terkonfirmasi akan hadir di acara ini. Sampai jumpa!'),
                    actions: [
                      TextButton(
                        child: const Text('Selesai'),
                        onPressed: () {
                          // Tutup pop-up
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
              // --- (AKHIR BAGIAN YANG DIGABUNG) ---
              child: const Text(
                'Konfirmasi Kehadiran',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Warna tombol
                foregroundColor: Colors.white, // Warna teks tombol
                minimumSize: const Size(double.infinity, 50), // Lebar penuh
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}