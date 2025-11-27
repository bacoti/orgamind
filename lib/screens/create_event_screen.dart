// lib/screens/create_event_screen.dart
// (VERSI UPDATE - SUDAH BISA PILIH JAM)

import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';

class CreateEventScreen extends StatefulWidget {
  final Function(EventModel) onSimpan;

  const CreateEventScreen({super.key, required this.onSimpan});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _speakerController = TextEditingController();
  
  DateTime? _selectedDate;
  
  // --- VARIABEL JAM (BARU) ---
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0); // Default jam 9
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);  // Default jam 12

  // Fungsi Pilih Tanggal
  void _pilihTanggal() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  // --- FUNGSI PILIH JAM (BARU) ---
  Future<void> _pilihJam(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredLocation = _locationController.text;
    final enteredDescription = _descriptionController.text;
    final enteredSpeaker = _speakerController.text;

    if (enteredTitle.isEmpty || enteredLocation.isEmpty || _selectedDate == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Input Tidak Lengkap'),
          content: const Text('Mohon pastikan Judul, Lokasi, dan Tanggal terisi.'),
          actions: [TextButton(child: const Text('Oke'), onPressed: () => Navigator.of(ctx).pop())],
        ),
      );
      return;
    }

    // --- GABUNGKAN JAM MENJADI STRING (CONTOH: "09:00 - 12:00 WIB") ---
    final String formattedTime = 
        '${_startTime.format(context)} - ${_endTime.format(context)} WIB';

    final acaraBaru = EventModel(
      id: DateTime.now().toString(),
      title: enteredTitle,
      location: enteredLocation,
      date: _selectedDate!,
      description: enteredDescription.isEmpty ? 'Deskripsi acara belum ditambahkan.' : enteredDescription,
      speakerName: enteredSpeaker.isEmpty ? 'Panitia' : enteredSpeaker,
      time: formattedTime, // <-- Masukkan jam hasil pilihan ke sini
    );

    widget.onSimpan(acaraBaru);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Acara Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INPUT JUDUL
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Acara',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 16),

              // 2. INPUT LOKASI
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Acara',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // 3. INPUT PEMBICARA
              TextField(
                controller: _speakerController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pembicara',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // 4. INPUT DESKRIPSI
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Acara',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // 5. PILIH TANGGAL & JAM (BARIS BARU)
              Row(
                children: [
                  // Kotak Tanggal
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: _pilihTanggal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded( // Agar teks tidak overflow
                              child: Text(
                                _selectedDate == null
                                    ? 'Pilih Tgl'
                                    : DateFormat('dd/MM/yy').format(_selectedDate!),
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Kotak Jam Mulai
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _pilihJam(true), // True = Start Time
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _startTime.format(context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text("-"),
                  ),

                  // Kotak Jam Selesai
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _pilihJam(false), // False = End Time
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _endTime.format(context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 6. TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Acara',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}