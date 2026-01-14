// lib/screens/participant_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';

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
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.init(); 
      final token = authService.getToken();
      
      if (token != null) {
        final data = await Provider.of<EventProvider>(context, listen: false)
            .getEventParticipants(widget.eventId, token);
        
        if (mounted) {
          setState(() {
            _participants = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeStatus(String userId, String status, String message) async {
    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();
    if (token == null) return;

    final success = await Provider.of<EventProvider>(context, listen: false)
        .updateParticipantStatus(widget.eventId, userId, status, token);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      _loadParticipants(); 
    }
  }

  Future<void> _removeParticipant(String userId) async {
    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();
    if (token == null) return;

    final success = await Provider.of<EventProvider>(context, listen: false)
        .removeParticipant(widget.eventId, userId, token);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peserta dihapus'), backgroundColor: Colors.red),
      );
      _loadParticipants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Peserta', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
              ? const Center(child: Text('Belum ada peserta.'))
              : ListView.separated(
                  itemCount: _participants.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _participants[index];
                    final String userId = p['id'].toString();
                    final String status = p['status'] ?? 'invited';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(status).withOpacity(0.1),
                        child: Text(
                          p['name'] != null && p['name'].toString().isNotEmpty
                              ? p['name'][0].toUpperCase()
                              : '?',
                          style: TextStyle(color: _getStatusColor(status)),
                        ),
                      ),
                      title: Text(p['name'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['email'] ?? '-'),
                          const SizedBox(height: 4),
                          _buildStatusLabel(status),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status != 'registered')
                            IconButton(
                              tooltip: 'Hadirkan Peserta',
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              onPressed: () => _changeStatus(userId, 'registered', 'Peserta berhasil dihadirkan'),
                            ),
                          
                          if (status != 'rejected')
                            IconButton(
                              tooltip: 'Tandai Tidak Hadir',
                              icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
                              onPressed: () => _changeStatus(userId, 'rejected', 'Peserta ditandai tidak hadir'),
                            ),

                          IconButton(
                            tooltip: 'Hapus Peserta',
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Hapus Peserta"),
                                  content: const Text("Yakin ingin menghapus peserta ini dari list?"),
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
                                      child: const Text("Hapus", style: TextStyle(color: Colors.red)),
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
    if (status == 'registered') return Colors.green;
    if (status == 'invited') return Colors.blue;
    if (status == 'rejected') return Colors.red;
    return Colors.grey;
  }

  Widget _buildStatusLabel(String status) {
    String label = status;
    Color color = _getStatusColor(status);

    if (status == 'registered') label = 'Hadir';
    if (status == 'invited') label = 'Diundang';
    if (status == 'rejected') label = 'Tidak Hadir';

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
    );
  }
}