// lib/screens/event_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';
import 'notification_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshEvents();
        }
      });
      _isInit = false;
    }
  }

  Future<void> _refreshEvents() async {
    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();
    final provider = Provider.of<EventProvider>(context, listen: false);

    // 1. Ambil Event Publik
    await provider.getAllEvents(token: token);

    // 2. Ambil Undangan (Agar muncul di list juga)
    if (token != null) {
      await provider.getUserInvitations(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text(
          'Daftar Event',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(), 
                ),
              ).then((_) => _refreshEvents());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        color: AppColors.primary,
        child: Consumer<EventProvider>(
          builder: (context, eventProvider, _) {
            if (eventProvider.isLoading && eventProvider.events.isEmpty) {
               return const Center(child: CircularProgressIndicator());
            }

            // GABUNGKAN Event Publik + Undangan
            // Kita pakai Map untuk menghilangkan duplikat berdasarkan ID
            final Map<int, EventModel> uniqueEvents = {};

            // Prioritaskan undangan (karena statusnya 'invited' yang kita butuhkan)
            for (var event in eventProvider.invitations) {
              event.status = 'invited'; // Pastikan status invited
              uniqueEvents[event.id] = event;
            }

            // Masukkan event publik (jangan timpa jika sudah ada di undangan)
            for (var event in eventProvider.events) {
              if (!uniqueEvents.containsKey(event.id)) {
                uniqueEvents[event.id] = event;
              }
            }

            final allEvents = uniqueEvents.values.toList();
            // Sort berdasarkan tanggal terbaru
            allEvents.sort((a, b) => b.date.compareTo(a.date));

            if (allEvents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada event tersedia',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allEvents.length,
              itemBuilder: (context, index) {
                final event = allEvents[index];
                return _buildEventCard(context, event);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    // Cek status untuk memberi tanda visual
    final isInvited = event.status == 'invited';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isInvited 
            ? const BorderSide(color: Colors.orange, width: 1.5) // Border oranye jika undangan
            : BorderSide.none,
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          ).then((_) {
            _refreshEvents();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Undangan (Jika ada)
              if (isInvited)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Undangan Masuk',
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  // Title & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy', 'id_ID').format(event.date),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Location
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}