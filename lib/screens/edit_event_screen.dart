// lib/screens/edit_event_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _categoryController;
  late TextEditingController _capacityController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi data awal dari event yang mau diedit
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _categoryController = TextEditingController(text: widget.event.category ?? '');
    _capacityController = TextEditingController(text: widget.event.capacity.toString());
    _selectedDate = widget.event.date;
    
    // Parse Jam Mulai
    _selectedTime = _parseTimeOfDay(widget.event.time);

    // Parse Jam Selesai (Jika ada, jika tidak ada default 3 jam setelah mulai)
    if (widget.event.endTime != null && widget.event.endTime!.isNotEmpty) {
      _selectedEndTime = _parseTimeOfDay(widget.event.endTime!);
    } else {
      int endHour = (_selectedTime!.hour + 3) % 24;
      _selectedEndTime = TimeOfDay(hour: endHour, minute: _selectedTime!.minute);
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _presentTimePicker(bool isStartTime) {
    showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? (_selectedTime ?? TimeOfDay.now()) 
          : (_selectedEndTime ?? TimeOfDay.now()),
    ).then((pickedTime) {
      if (pickedTime == null) return;
      setState(() {
        if (isStartTime) {
          _selectedTime = pickedTime;
        } else {
          _selectedEndTime = pickedTime;
        }
      });
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null || _selectedTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi tanggal dan waktu (Mulai & Selesai)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.init(); // <--- INI PERBAIKANNYA (Wajib init dulu sebelum getToken)
      final token = authService.getToken();

      if (token != null) {
        final eventProvider = Provider.of<EventProvider>(context, listen: false);
        
        // Format Waktu ke "HH:mm:ss"
        final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
        final endTimeString = '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}:00';
        
        // Format Tanggal ke "YYYY-MM-DD"
        final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);

        final success = await eventProvider.updateEvent(
          token: token,
          eventId: widget.event.id,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          date: dateString,
          time: timeString,
          endTime: endTimeString, // Kirim End Time yang baru
          category: _categoryController.text,
          capacity: int.parse(_capacityController.text),
        );

        if (success && mounted) {
          Navigator.pop(context, true); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event berhasil diperbarui!'), backgroundColor: Colors.green),
          );
        } else {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(eventProvider.errorMessage ?? 'Gagal update'), backgroundColor: Colors.red),
            );
           }
        }
      } else {
        throw Exception("Token tidak ditemukan");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Acara'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Input Judul
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Judul Acara', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Judul tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Lokasi
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Lokasi tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Deskripsi
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Row Tanggal & Waktu
                    Row(
                      children: [
                        // Tanggal
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: _presentDatePicker,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Jam Mulai
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () => _presentTimePicker(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Mulai',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              ),
                              child: Text(
                                _selectedTime?.format(context) ?? 'Jam',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Jam Selesai
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () => _presentTimePicker(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Selesai',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              ),
                              child: Text(
                                _selectedEndTime?.format(context) ?? 'Jam',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Input Kategori
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Kapasitas
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Kapasitas', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    
                    // Tombol Simpan
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}