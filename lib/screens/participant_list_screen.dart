// lib/screens/participant_list_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/api_config.dart';

class ParticipantListScreen extends StatefulWidget {
  final int eventId;
  const ParticipantListScreen({super.key, required this.eventId});

  @override
  State<ParticipantListScreen> createState() => _ParticipantListScreenState();
}

class _ParticipantListScreenState extends State<ParticipantListScreen> {
  bool _isLoading = true;
  List<dynamic> _participants = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParticipants();
    });
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();

      if (!mounted) return;

      if (token != null) {
        final data = await Provider.of<EventProvider>(
          context,
          listen: false,
        ).getEventParticipants(widget.eventId, token);

        if (mounted) {
          setState(() {
            _participants = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _participants = [];
            _isLoading = false;
            _errorMessage = 'Sesi kamu habis. Silakan login ulang.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _participants = [];
          _isLoading = false;
          _errorMessage = 'Gagal memuat daftar peserta. Coba lagi.';
        });
      }
    }
  }

  Future<void> _changeStatus(
    String userId,
    String status,
    String message,
  ) async {
    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();
    if (token == null) return;

    if (!mounted) return;

    final success = await Provider.of<EventProvider>(
      context,
      listen: false,
    ).updateParticipantStatus(widget.eventId, userId, status, token);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      _loadParticipants();
    }
  }

  /// Manual check-in peserta (presensi manual oleh admin)
  Future<void> _manualCheckIn(String userId) async {
    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.attendanceManual(widget.eventId)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({'userId': int.parse(userId)}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peserta berhasil diabsen (hadir)'),
            backgroundColor: Colors.green,
          ),
        );
        _loadParticipants();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal melakukan presensi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeParticipant(String userId) async {
    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();
    if (token == null) return;

    if (!mounted) return;

    final success = await Provider.of<EventProvider>(
      context,
      listen: false,
    ).removeParticipant(widget.eventId, userId, token);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peserta dihapus'),
          backgroundColor: Colors.red,
        ),
      );
      _loadParticipants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Peserta',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadParticipants,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _participants.isEmpty
          ? const Center(child: Text('Belum ada peserta.'))
          : ListView.separated(
              itemCount: _participants.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = _participants[index];
                final String userId = p['id'].toString();
                // Gunakan display_status dari backend yang sudah memperhitungkan attendance
                final String displayStatus = p['display_status'] ?? p['status'] ?? 'invited';
                final String baseStatus = p['status'] ?? 'invited';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(
                      displayStatus,
                    ).withValues(alpha: 0.1),
                    child: Text(
                      p['name'] != null && p['name'].toString().isNotEmpty
                          ? p['name'][0].toUpperCase()
                          : '?',
                      style: TextStyle(color: _getStatusColor(displayStatus)),
                    ),
                  ),
                  title: Text(
                    p['name'] ?? 'Tanpa Nama',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['email'] ?? '-'),
                      const SizedBox(height: 4),
                      _buildStatusLabel(displayStatus),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Presensi Manual - hanya muncul jika status registered dan belum hadir
                      if (baseStatus == 'registered' && displayStatus != 'attended')
                        IconButton(
                          tooltip: 'Presensi Manual (Hadir)',
                          icon: const Icon(
                            Icons.how_to_reg,
                            color: Colors.teal,
                          ),
                          onPressed: () => _manualCheckIn(userId),
                        ),

                      // Tombol Terima Undangan - hanya untuk status invited
                      if (displayStatus == 'invited')
                        IconButton(
                          tooltip: 'Terima Undangan (Terdaftar)',
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () => _changeStatus(
                            userId,
                            'registered',
                            'Peserta berhasil terdaftar',
                          ),
                        ),

                      // Tombol Tolak - tidak muncul jika sudah hadir
                      if (displayStatus != 'rejected' && displayStatus != 'attended')
                        IconButton(
                          tooltip: 'Tolak/Batalkan',
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.orange,
                          ),
                          onPressed: () => _changeStatus(
                            userId,
                            'rejected',
                            'Peserta ditolak/dibatalkan',
                          ),
                        ),

                      IconButton(
                        tooltip: 'Hapus Peserta',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Hapus Peserta"),
                              content: const Text(
                                "Yakin ingin menghapus peserta ini dari list?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _removeParticipant(userId);
                                  },
                                  child: const Text(
                                    "Hapus",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'attended':
        return Colors.teal; // Sudah hadir (presensi)
      case 'registered':
        return Colors.green; // Terdaftar (terima undangan)
      case 'invited':
        return Colors.blue; // Diundang (belum konfirmasi)
      case 'rejected':
        return Colors.red; // Ditolak
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusLabel(String status) {
    String label;
    IconData icon;
    Color color = _getStatusColor(status);

    switch (status) {
      case 'attended':
        label = 'Hadir';
        icon = Icons.check_circle;
        break;
      case 'registered':
        label = 'Terdaftar';
        icon = Icons.how_to_reg;
        break;
      case 'invited':
        label = 'Diundang';
        icon = Icons.mail_outline;
        break;
      case 'rejected':
        label = 'Ditolak';
        icon = Icons.cancel;
        break;
      default:
        label = status;
        icon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
