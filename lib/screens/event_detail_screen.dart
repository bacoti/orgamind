// lib/screens/event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
import 'edit_event_screen.dart';
import 'invite_participants_screen.dart';
import 'participant_list_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late String _currentStatus;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Gunakan status dari model. Jika null (misal dari list publik), anggap 'unknown'
    _currentStatus = widget.event.status ?? 'unknown'; 
  }

  Future<void> _handleInvitationResponse(String action) async {
    setState(() => _isProcessing = true);

    try {
      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();

      if (token != null && mounted) {
        final success = await Provider.of<EventProvider>(context, listen: false)
            .respondToInvitation(widget.event.id, action, token);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(action == 'accept' ? 'Undangan diterima!' : 'Undangan ditolak'),
                backgroundColor: action == 'accept' ? Colors.green : Colors.red,
              ),
            );
            Navigator.pop(context, true); // Kembali dan refresh list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal memproses permintaan'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    
    // Logika tombol: HANYA muncul jika status == 'invited' DAN user bukan admin
    final showActionButtons = _currentStatus == 'invited' && !isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Acara',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Edit',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventScreen(event: widget.event),
                  ),
                ).then((result) {
                  if (result == true) Navigator.pop(context, true);
                });
              },
              icon: const Icon(Icons.edit, color: AppColors.primary),
            ),
             IconButton(
              tooltip: 'Delete',
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Acara'),
                          content: const Text('Apakah Anda yakin ingin menghapus acara ini?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  // Logic delete provider bisa ditambahkan di sini
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                          ],
                        ));
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: AppColors.gray50,
                    child: widget.event.imageUrl != null 
                        ? Image.network(widget.event.imageUrl!, fit: BoxFit.cover, 
                            errorBuilder: (c, o, s) => Icon(Icons.image, size: 80, color: AppColors.gray300))
                        : Icon(Icons.image, size: 80, color: AppColors.gray300),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.event.category != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.event.category!,
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),

                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildInfoRow(Icons.calendar_today, DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(widget.event.date)),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.access_time, widget.event.time),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on, widget.event.location),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.person, "Penyelenggara: ${widget.event.organizerName ?? 'Admin'}"),
                        
                        // Status Badge (Untuk User Biasa)
                        if (!isAdmin) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_currentStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getStatusColor(_currentStatus)),
                            ),
                            child: Text(
                              'Status Anda: ${_translateStatus(_currentStatus)}',
                              style: TextStyle(
                                color: _getStatusColor(_currentStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 30),
                        const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          widget.event.description, 
                          style: TextStyle(color: Colors.grey[600], height: 1.5)
                        ),

                        // Tombol Admin (Lihat Peserta & Undang)
                        if (isAdmin) ...[
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParticipantListScreen(eventId: widget.event.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.people_alt_outlined),
                              label: const Text('Lihat Daftar Peserta'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InviteParticipantsScreen(
                                      eventId: widget.event.id.toString(),
                                      eventTitle: widget.event.title,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Undang Peserta'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- TOMBOL TERIMA / TOLAK (Hanya Muncul Jika Status 'invited') ---
          if (showActionButtons) 
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: _isProcessing 
              ? const Center(child: CircularProgressIndicator())
              : Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                    onPressed: () => _handleInvitationResponse('reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tolak Undangan'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton(
                    onPressed: () => _handleInvitationResponse('accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Terima Undangan', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'registered') return Colors.green;
    if (status == 'invited') return Colors.orange;
    if (status == 'rejected') return Colors.red;
    return Colors.grey;
  }

  String _translateStatus(String status) {
    if (status == 'registered') return 'Terdaftar (Hadir)';
    if (status == 'invited') return 'Menunggu Konfirmasi (Diundang)';
    if (status == 'rejected') return 'Undangan Ditolak';
    return status;
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