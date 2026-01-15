// lib/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pastikan intl diimport untuk DateFormat
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import 'event_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadInvitations();
      _isInit = false;
    }
  }

  Future<void> _loadInvitations() async {
    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();

    if (token != null && mounted) {
      // Ambil data undangan terbaru
      await Provider.of<EventProvider>(
        context,
        listen: false,
      ).getUserInvitations(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Background putih bersih seperti halaman pesan
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          if (eventProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final invitations = eventProvider.invitations;

          if (invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi baru',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadInvitations,
            child: ListView.separated(
              itemCount: invitations.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final event = invitations[index];

                // Set status agar detail screen tahu ini undangan
                event.status = 'invited';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.mail_outline, color: AppColors.primary),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        const TextSpan(text: 'Anda telah diundang ke event '),
                        TextSpan(
                          text: event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      DateFormat(
                        'dd MMM yyyy • HH:mm',
                        'id_ID',
                      ).format(event.date),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                  onTap: () {
                    // Saat diklik, arahkan ke Detail Event untuk aksi Terima/Tolak
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(event: event),
                      ),
                    ).then((value) {
                      if (value == true) {
                        _loadInvitations(); // Refresh jika status berubah
                      }
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
