// lib/screens/create_event_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _capacityController = TextEditingController(text: '100');
  
  DateTime? _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0); // Default end time

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

  Future<void> _submitData() async {
    final enteredTitle = _titleController.text;
    final enteredLocation = _locationController.text;
    final enteredDescription = _descriptionController.text;
    final enteredCategory = _categoryController.text;
    final capacity = int.tryParse(_capacityController.text) ?? 100;

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

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();

      if (token == null) throw Exception('Token not found');

      // Format Start Time (HH:mm:ss)
      final timeString = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
      
      // Format End Time (HH:mm:ss) -- BARU
      final endTimeString = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';
      
      // Format Date (YYYY-MM-DD)
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final success = await eventProvider.createEvent(
        token: token,
        title: enteredTitle,
        description: enteredDescription.isEmpty ? 'Deskripsi acara' : enteredDescription,
        location: enteredLocation,
        date: dateString,
        time: timeString,
        endTime: endTimeString, // <--- KIRIM END TIME
        category: enteredCategory.isEmpty ? 'Umum' : enteredCategory,
        capacity: capacity,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event berhasil dibuat!')));
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: Text(eventProvider.errorMessage ?? 'Gagal membuat event'),
              actions: [TextButton(child: const Text('Oke'), onPressed: () => Navigator.of(ctx).pop())],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text('Terjadi kesalahan: $e'),
            actions: [TextButton(child: const Text('Oke'), onPressed: () => Navigator.of(ctx).pop())],
          ),
        );
      }
    }
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
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Acara', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lokasi Acara', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi Acara', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description), alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              
              // ROW: Tanggal, Start Time, End Time
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: _pilihTanggal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_selectedDate == null ? 'Pilih Tgl' : DateFormat('dd/MM/yy').format(_selectedDate!), style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _pilihJam(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Text(_startTime.format(context), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Text("-")),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _pilihJam(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Text(_endTime.format(context), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Simpan Acara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}