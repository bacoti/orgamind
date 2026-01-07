// lib/screens/edit_event_screen.dart
// Screen untuk mengedit event yang sudah ada

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../models/event_model.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;
  
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _capacityController;
  
  DateTime? _selectedDate;
  late TimeOfDay _startTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill dengan data event yang sudah ada
    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location);
    _descriptionController = TextEditingController(text: widget.event.description);
    _categoryController = TextEditingController(text: widget.event.category ?? '');
    _capacityController = TextEditingController(text: widget.event.capacity.toString());
    _selectedDate = widget.event.date;
    
    // Parse time dari string (format: HH:mm:ss atau HH:mm)
    final timeParts = widget.event.time.split(':');
    _startTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 9,
      minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _pilihTanggal() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  Future<void> _pilihJam() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
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

    setState(() => _isLoading = true);

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();

      if (token == null) {
        throw Exception('Token not found');
      }

      // Format time untuk backend (HH:mm:ss)
      final timeString = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
      
      // Format date untuk backend (YYYY-MM-DD)
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final success = await eventProvider.updateEvent(
        token: token,
        eventId: widget.event.id,
        title: enteredTitle,
        description: enteredDescription.isEmpty ? 'Deskripsi acara' : enteredDescription,
        location: enteredLocation,
        date: dateString,
        time: timeString,
        category: enteredCategory.isEmpty ? 'Umum' : enteredCategory,
        capacity: capacity,
      );

      if (!mounted) return;
      
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true untuk refresh
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(eventProvider.errorMessage ?? 'Gagal memperbarui event'),
            actions: [TextButton(child: const Text('Oke'), onPressed: () => Navigator.of(ctx).pop())],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Acara'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event ID info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.gray600),
                    const SizedBox(width: 8),
                    Text(
                      'Event ID: ${widget.event.id}',
                      style: TextStyle(color: AppColors.gray600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // INPUT JUDUL
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Acara',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 16),

              // INPUT LOKASI
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Acara',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // INPUT DESKRIPSI
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

              // INPUT KATEGORI
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // INPUT KAPASITAS
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kapasitas Peserta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
              ),
              const SizedBox(height: 16),

              // PILIH TANGGAL & JAM
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
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd MMM yyyy').format(_selectedDate!),
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Kotak Jam
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _pilihJam,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              _startTime.format(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitData,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // TOMBOL BATAL
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 16),
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
