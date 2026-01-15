// lib/screens/event_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> with SingleTickerProviderStateMixin {
  bool _isInit = true;
  final Set<int> _readNotificationIds = {};
  
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  late TextEditingController _searchController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshEvents();
      });
      _isInit = false;
    }
  }

  Future<void> _refreshEvents() async {
    try {
      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();
      if (mounted && token != null) {
        final provider = Provider.of<EventProvider>(context, listen: false);
        await provider.getUserInvitations(token);
      }
    } catch (e) {
      debugPrint("Error loading events: $e");
    }
  }

  // --- POP-UP NOTIFIKASI (VERSI STABIL / NO CRASH) ---
  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black12, // Overlay transparan gelap
      barrierDismissible: true,
      builder: (context) {
        // Gunakan StatefulBuilder untuk update lokal (titik merah)
        return StatefulBuilder(
          builder: (context, setStatePopup) {
            return Stack(
              children: [
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 5,
                    child: Container(
                      width: 320,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          
                          // List Notifikasi
                          Flexible(
                            child: Consumer<EventProvider>(
                              builder: (context, eventProvider, _) {
                                final invitations = eventProvider.invitations;
                                final pendingInvitations = invitations
                                    .where((e) => e.status == 'invited')
                                    .toList();
                                pendingInvitations.sort((a, b) => b.date.compareTo(a.date));

                                if (pendingInvitations.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.notifications_none, size: 40, color: Colors.grey[300]),
                                          const SizedBox(height: 8),
                                          Text('Tidak ada undangan baru', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                        ],
                                      ),
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
                                    final bool isRead = _readNotificationIds.contains(event.id);

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isRead ? Colors.grey[100] : AppColors.primary.withOpacity(0.1),
                                        child: Icon(Icons.mail, color: isRead ? Colors.grey : AppColors.primary, size: 20),
                                      ),
                                      title: Text(
                                        event.title,
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 13,
                                          color: isRead ? Colors.grey[700] : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        'Undangan • ${DateFormat('dd MMM').format(event.date)}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                      ),
                                      trailing: !isRead 
                                        ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                                        : null,
                                      onTap: () {
                                        setStatePopup(() => _readNotificationIds.add(event.id));
                                        this.setState(() {}); 
                                        Navigator.pop(context);
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)))
                                            .then((v) { if (v == true) _refreshEvents(); });
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
      }
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 10) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final userName = user?.name.split(' ')[0] ?? 'Peserta';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // --- HEADER ---
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 160.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0061FF), Color(0xFF60EFFF)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Dekorasi lingkaran
                      Positioned(top: -50, right: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.1))),
                      Positioned(bottom: -30, left: -30, child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.1))),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Text(userInitial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_getGreeting(), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Consumer<EventProvider>(
                    builder: (context, eventProvider, child) {
                      final invitations = eventProvider.invitations;
                      final pendingInvitations = invitations.where((e) => e.status == 'invited').toList();
                      final int unreadCount = pendingInvitations.where((e) => !_readNotificationIds.contains(e.id)).length;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                            onPressed: () => _showNotificationPopup(context),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8, top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Center(
                                  child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            // --- STICKY SEARCH & FILTER ---
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  color: AppColors.primary, // Warna biru agar menyatu dengan header
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: const InputDecoration(
                            hintText: 'Cari acara...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Semua'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Undangan'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Jadwal'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                maxHeight: 130,
                minHeight: 130,
              ),
            ),

            // --- LIST CONTENT ---
            Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                if (eventProvider.isLoading && eventProvider.invitations.isEmpty) {
                   return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }

                var allEvents = List<EventModel>.from(eventProvider.invitations);
                if (_searchQuery.isNotEmpty) {
                  allEvents = allEvents.where((e) => e.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }
                if (_selectedFilter == 'Undangan') {
                  allEvents = allEvents.where((e) => e.status == 'invited').toList();
                } else if (_selectedFilter == 'Jadwal') {
                  allEvents = allEvents.where((e) => e.status == 'registered').toList();
                }

                allEvents.sort((a, b) {
                  if (a.status == 'invited' && b.status != 'invited') return -1;
                  if (a.status != 'invited' && b.status == 'invited') return 1;
                  return a.date.compareTo(b.date);
                });

                if (allEvents.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text("Belum ada event")));
                }

                final invitedEvents = allEvents.where((e) => e.status == 'invited').toList();
                final registeredEvents = allEvents.where((e) => e.status != 'invited').toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (invitedEvents.isNotEmpty && (_selectedFilter == 'Semua' || _selectedFilter == 'Undangan')) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Undangan Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: invitedEvents.length,
                          separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                          itemBuilder: (context, index) => _buildTicketCard(invitedEvents[index]),
                        ),
                      ),
                    ],

                    if (registeredEvents.isNotEmpty && (_selectedFilter == 'Semua' || _selectedFilter == 'Jadwal')) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text('Jadwal Mendatang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ...registeredEvents.map((e) => _buildScheduleCard(e)),
                    ],
                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(EventModel event) {
    return GestureDetector(
      onTap: () {
        setState(() => _readNotificationIds.add(event.id));
        Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)))
            .then((_) => _refreshEvents());
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF3A3A3A)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                  child: const Text('BUTUH RESPON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(DateFormat('d MMM yyyy').format(event.date), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text(event.location, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(EventModel event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)))
            .then((_) => _refreshEvents());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(DateFormat('dd').format(event.date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(DateFormat('MMM').format(event.date), style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${event.time} • ${event.location}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight, minHeight;
  _StickyHeaderDelegate({required this.child, required this.maxHeight, required this.minHeight});
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);
  @override double get maxExtent => maxHeight;
  @override double get minExtent => minHeight;
  @override bool shouldRebuild(_StickyHeaderDelegate oldDelegate) => maxHeight != oldDelegate.maxExtent || minHeight != oldDelegate.minExtent || child != oldDelegate.child;
}