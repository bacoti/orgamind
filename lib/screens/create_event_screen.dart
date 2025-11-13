import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart'; // Kita pakai model yang sama

class CreateEventScreen extends StatefulWidget {
  // Kita butuh fungsi 'onSimpan' dari halaman sebelumnya
  // untuk mengirim data kembali
  final Function(EventModel) onSimpan;

  const CreateEventScreen({Key? key, required this.onSimpan}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // Controller untuk mengambil teks dari formulir
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate; // Variabel untuk menyimpan tanggal

  // --- FUNGSI UNTUK MENAMPILKAN KALENDER ---
  void _pilihTanggal() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  // --- FUNGSI UNTUK SIMPAN DATA ---
  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredLocation = _locationController.text;

    // Validasi sederhana: Pastikan semua data terisi
    if (enteredTitle.isEmpty ||
        enteredLocation.isEmpty ||
        _selectedDate == null) {
      // Tampilkan error jika ada yang kosong
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Input Tidak Lengkap'),
          content: const Text(
              'Mohon pastikan Judul Acara, Lokasi, dan Tanggal sudah terisi.'),
          actions: [
            TextButton(
              child: const Text('Oke'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return; // Hentikan fungsi
    }

    // Buat model event baru
    final acaraBaru = EventModel(
      // Kita buat ID unik berdasarkan waktu
      id: DateTime.now().toString(), 
      title: enteredTitle,
      location: enteredLocation,
      date: _selectedDate!,
    );

    // Kirim data baru kembali ke halaman list
    widget.onSimpan(acaraBaru);

    // Tutup halaman formulir
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Acara Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. FORMULIR JUDUL
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Acara',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 2. FORMULIR LOKASI
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lokasi Acara',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 3. PEMILIH TANGGAL
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Tanggal belum dipilih'
                        : 'Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: _pilihTanggal,
                  child: const Text(
                    'Pilih Tanggal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. TOMBOL SIMPAN
            ElevatedButton(
              onPressed: _submitData,
              child: const Text(
                'Simpan Acara',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
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