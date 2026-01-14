// lib/screens/event_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  bool _isInit = true;
  
  // Set untuk menyimpan ID notifikasi yang sudah dibaca/diklik
  final Set<int> _readNotificationIds = {}; 

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
    
    if (mounted && token != null) {
      final provider = Provider.of<EventProvider>(context, listen: false);
      await provider.getUserInvitations(token);
    }
  }

  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        // Kita butuh StatefulBuilder di dalam dialog agar bisa update tampilan (titik biru)
        // saat item diklik tanpa menutup dialog jika diinginkan, atau update parent saat kembali.
        return StatefulBuilder(
          builder: (context, setStatePopup) {
            return Stack(
              children: [
                // Overlay transparan untuk menutup saat klik luar
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.black.withOpacity(0.05)),
                  ),
                ),
                // Posisi Bubble Pop-up
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 320,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Pop-up
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Notifikasi',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          
                          // List Notifikasi
                          Flexible(
                            child: Consumer<EventProvider>(
                              builder: (context, eventProvider, _) {
                                // Filter hanya undangan yang belum direspon (status 'invited')
                                final pendingInvitations = eventProvider.invitations
                                    .where((e) => e.status == 'invited')
                                    .toList();

                                // Sort agar yang terbaru di atas
                                pendingInvitations.sort((a, b) => b.date.compareTo(a.date));

                                if (pendingInvitations.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_none, size: 40, color: Colors.grey[300]),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tidak ada notifikasi baru',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: pendingInvitations.length,
                                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final event = pendingInvitations[index];
                                    
                                    // Cek apakah ID ini sudah pernah diklik
                                    final bool isRead = _readNotificationIds.contains(event.id);

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        child: Icon(Icons.mail, color: AppColors.primary, size: 18),
                                      ),
                                      title: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(color: Colors.black, fontSize: 13),
                                          children: [
                                            const TextSpan(text: 'Undangan: '),
                                            TextSpan(
                                              text: event.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('dd MMM • HH:mm').format(event.date),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                      ),
                                      // LOGIKA TITIK BIRU: Hanya muncul jika BELUM dibaca
                                      trailing: !isRead 
                                        ? Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null, // Hilang jika sudah dibaca
                                      onTap: () {
                                        // 1. Tandai sudah dibaca di Parent Widget (EventListScreen)
                                        // Gunakan setState parent agar badge merah di appbar terupdate
                                        this.setState(() {
                                          _readNotificationIds.add(event.id);
                                        });

                                        // 2. Update tampilan Pop-up (titik biru hilang)
                                        setStatePopup(() {});

                                        // 3. Tutup Pop-up
                                        Navigator.pop(context);
                                        
                                        // 4. Buka Detail
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EventDetailScreen(event: event),
                                          ),
                                        ).then((value) {
                                          // Refresh data jika ada aksi (misal terima undangan)
                                          if (value == true) _refreshEvents();
                                        });
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Acara Saya',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- LOGIKA BADGE ANGKA MERAH ---
          Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              // Hitung jumlah undangan yang statusnya 'invited'
              final pendingInvitations = eventProvider.invitations
                  .where((e) => e.status == 'invited')
                  .toList();
              
              // Hitung berapa banyak yang BELUM DIBACA
              // (Pending Invitation DIKURANGI yang ada di _readNotificationIds)
              final int unreadCount = pendingInvitations
                  .where((e) => !_readNotificationIds.contains(e.id))
                  .length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                    onPressed: () => _showNotificationPopup(context),
                  ),
                  // Hanya tampil jika ada notifikasi BELUM DIBACA
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.0, 
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        color: AppColors.primary,
        child: Consumer<EventProvider>(
          builder: (context, eventProvider, _) {
            if (eventProvider.isLoading && eventProvider.invitations.isEmpty) {
               return const Center(child: CircularProgressIndicator());
            }

            final myEvents = eventProvider.invitations;
            myEvents.sort((a, b) => b.date.compareTo(a.date)); // Sort: Terbaru di atas

            if (myEvents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada acara',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myEvents.length,
              itemBuilder: (context, index) {
                final event = myEvents[index];
                return _buildEventCard(context, event);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final isInvited = event.status == 'invited';
    final isRegistered = event.status == 'registered';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isInvited 
            ? const BorderSide(color: Colors.orange, width: 1.5) 
            : BorderSide.none,
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Tandai sudah dibaca juga saat klik dari list utama
          // Gunakan setState agar badge merah di appbar terupdate
          setState(() {
            _readNotificationIds.add(event.id);
          });

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
              if (isInvited)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Undangan Baru',
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              else if (isRegistered)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Akan Hadir',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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