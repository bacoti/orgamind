// lib/screens/event_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Untuk ImageFilter
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

  // --- POP-UP NOTIFIKASI GLASSMORPHISM ---
  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStatePopup) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                  ),
                ),
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
                  right: 20,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      width: 340,
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
                          BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                           child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                                        SizedBox(width: 10),
                                        Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                      ],
                                    ),
                                    _BouncingButton(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              Flexible(
                                child: Consumer<EventProvider>(
                                  builder: (context, eventProvider, _) {
                                    final invitations = eventProvider.invitations;
                                    final pendingInvitations = invitations.where((e) => e.status == 'invited').toList();
                                    pendingInvitations.sort((a, b) => b.date.compareTo(a.date));

                                    if (pendingInvitations.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(40.0),
                                        child: Column(
                                          children: [
                                            Icon(Icons.mark_email_read_rounded, size: 60, color: Colors.grey[300]),
                                            const SizedBox(height: 16),
                                            Text('Semua beres!', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text('Tidak ada undangan baru untuk saat ini.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      itemCount: pendingInvitations.length,
                                      separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70, endIndent: 20),
                                      itemBuilder: (context, index) {
                                        final event = pendingInvitations[index];
                                        final bool isRead = _readNotificationIds.contains(event.id);

                                        return _BouncingButton(
                                          onTap: () {
                                            setStatePopup(() => _readNotificationIds.add(event.id));
                                            this.setState(() {});
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)))
                                                .then((v) { if (v == true) _refreshEvents(); });
                                          },
                                          child: Container(
                                            color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.03),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: isRead ? Colors.grey[100] : Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: isRead ? [] : [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                                                  ),
                                                  child: Icon(Icons.mail_rounded, color: isRead ? Colors.grey[400] : AppColors.primary, size: 22),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        event.title,
                                                        style: TextStyle(
                                                          fontWeight: isRead ? FontWeight.normal : FontWeight.w800,
                                                          fontSize: 14,
                                                          color: isRead ? Colors.grey[700] : Colors.black87,
                                                        ),
                                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        DateFormat('dd MMMM, HH:mm', 'id_ID').format(event.date),
                                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (!isRead)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 10),
                                                  width: 10, height: 10,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFF3B30), // Merah Apple
                                                    shape: BoxShape.circle,
                                                    boxShadow: [BoxShadow(color: const Color(0xFFFF3B30).withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 2))]
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
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
                  ),
                ),
              ],
            );
          }
        );
      },
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
      backgroundColor: const Color(0xFFF0F2F5), // Warna background premium light gray
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // --- 1. ANIMATED SLIVER HEADER (Perbaikan "Cacat" Transisi) ---
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 160.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              stretch: true, // Efek stretch saat ditarik
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Hitung persentase collapse (0.0 = expanded, 1.0 = collapsed)
                  final double percentage = (constraints.maxHeight - kToolbarHeight) / (160.0 - kToolbarHeight);
                  final double fadeOut = (percentage - 0.5).clamp(0.0, 1.0) * 2.0; // Fade out konten besar
                  final double fadeIn = 1.0 - percentage.clamp(0.0, 1.0); // Fade in title kecil

                  return FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Gradient Background
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0061FF), Color(0xFF60EFFF)], // Electric Blue Gradient
                            ),
                          ),
                        ),
                        // Pola Abstrak (Opsional, bisa diganti gambar)
                        Opacity(
                          opacity: 0.1,
                          child: Image.network(
                            "https://img.freepik.com/free-vector/abstract-blue-geometric-shapes-background_1035-17545.jpg?w=1380&t=st=1705245000~exp=1705245600~hmac=...", // Ganti dengan aset lokal jika ada
                            fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => const SizedBox(), // Fallback jika offline
                          ),
                        ),
                        // Konten Besar (Fade Out saat scroll)
                        Opacity(
                          opacity: fadeOut,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    child: Text(userInitial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_getGreeting(), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Title Kecil (Fade In saat collapsed)
                    title: Opacity(
                      opacity: fadeIn,
                      child: Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                    centerTitle: true,
                  );
                },
              ),
              actions: [
                // Notifikasi Icon (Selalu muncul)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Consumer<EventProvider>(
                    builder: (context, eventProvider, child) {
                      final invitations = eventProvider.invitations;
                      final pendingInvitations = invitations.where((e) => e.status == 'invited').toList();
                      final int unreadCount = pendingInvitations.where((e) => !_readNotificationIds.contains(e.id)).length;

                      return Center(
                        child: _BouncingButton(
                          onTap: () => _showNotificationPopup(context),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: -4, right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                                    ),
                                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                    child: Center(child: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1.0))),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // --- 2. STICKY SEARCH & FILTER (Menempel saat scroll) ---
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  color: const Color(0xFFF0F2F5), // Warna sama dengan background body
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    children: [
                      // Search Bar Modern
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Cari acara...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary.withOpacity(0.6)),
                            suffixIcon: _searchQuery.isNotEmpty 
                              ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                }) 
                              : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildAnimatedChip('Semua'),
                            const SizedBox(width: 12),
                            _buildAnimatedChip('Undangan'),
                            const SizedBox(width: 12),
                            _buildAnimatedChip('Jadwal'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                maxHeight: 130, // Tinggi total area sticky
                minHeight: 130,
              ),
            ),

            // --- 3. KONTEN LIST EVENT ---
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
                  return const SliverFillRemaining(child: _EmptyStateWidget());
                }

                final invitedEvents = allEvents.where((e) => e.status == 'invited').toList();
                final registeredEvents = allEvents.where((e) => e.status != 'invited').toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // A. SECTION UNDANGAN (TICKET STYLE)
                    if (invitedEvents.isNotEmpty && (_selectedFilter == 'Semua' || _selectedFilter == 'Undangan')) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Row(
                          children: [
                            Icon(Icons.local_activity_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Tiket Undangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 190,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: invitedEvents.length,
                          separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                          itemBuilder: (context, index) => _buildRealTicketCard(context, invitedEvents[index]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // B. SECTION JADWAL (CLEAN STYLE)
                    if (registeredEvents.isNotEmpty && (_selectedFilter == 'Semua' || _selectedFilter == 'Jadwal')) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Jadwal Mendatang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                          ],
                        ),
                      ),
                      ...registeredEvents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final event = entry.value;
                        // Staggered Animation untuk list vertikal
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeOutQuad,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: _buildCleanScheduleCard(context, event),
                          ),
                        );
                      }),
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

  // --- WIDGET: ANIMATED FILTER CHIP ---
  Widget _buildAnimatedChip(String label) {
    final isSelected = _selectedFilter == label;
    return _BouncingButton(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- WIDGET: KARTU UNDANGAN (TICKET STYLE NYATA) ---
  Widget _buildRealTicketCard(BuildContext context, EventModel event) {
    return _BouncingButton(
      onTap: () {
        setState(() => _readNotificationIds.add(event.id));
        Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)))
            .then((_) => _refreshEvents());
      },
      child: Container(
        width: 300,
        child: Stack(
          children: [
            // Main Ticket Body
            Container(
              margin: const EdgeInsets.only(right: 10), // Space for rip effect
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF232526), Color(0xFF414345)], // Premium Dark Gradient
                ),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(5)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(8)),
                          child: const Text('BUTUH RESPON', style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                        Text(DateFormat('d MMM yyyy', 'id_ID').format(event.date), style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.6), size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(event.location, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Garis Putus-putus
            Positioned(
              right: 10, top: 10, bottom: 10,
              child: CustomPaint(
                size: const Size(1, double.infinity),
                painter: _DashedLinePainter(color: Colors.white.withOpacity(0.3)),
              ),
            ),
             // "Sobekan" Kanan (Stub)
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: Container(
                width: 10,
                decoration: const BoxDecoration(
                   gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF2E3133), Color(0xFF4B4D4F)],
                  ),
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                ),
              ),
            ),
            // Lingkaran Pemotong Atas & Bawah
            Positioned(right: 5, top: -10, child: CircleAvatar(radius: 10, backgroundColor: const Color(0xFFF0F2F5))),
            Positioned(right: 5, bottom: -10, child: CircleAvatar(radius: 10, backgroundColor: const Color(0xFFF0F2F5))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: KARTU JADWAL (CLEAN PREMIUM STYLE) ---
  Widget _buildCleanScheduleCard(BuildContext context, EventModel event) {
    return _BouncingButton(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)))
            .then((_) => _refreshEvents());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tanggal dengan Accent Bar
              Container(
                height: 70, width: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(left: 0, top: 15, bottom: 15, child: Container(width: 3, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)))),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('dd').format(event.date), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1.0)),
                          Text(DateFormat('MMM').format(event.date).toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(event.time, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Expanded(child: Text(event.location, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500), maxLines: 1)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFE6F9F0), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00C853).withOpacity(0.2))),
                child: const Icon(Icons.check_rounded, color: Color(0xFF00C853), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET HELPER: EMPTY STATE ---
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle)),
                const Icon(Icons.event_busy_rounded, size: 60, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Belum Ada Jadwal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('Tenang, saat ini belum ada agenda.\nUndangan atau jadwal akan muncul di sini!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET HELPER: BOUNCING BUTTON (Micro-interaction) ---
class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BouncingButton({required this.child, required this.onTap});
  @override
  __BouncingButtonState createState() => __BouncingButtonState();
}
class __BouncingButtonState extends State<_BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

// --- PAINTER: GARIS PUTUS-PUTUS ---
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 5, startY = 0;
    final paint = Paint()..color = color..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- DELEGATE: STICKY HEADER ---
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight, minHeight;
  _StickyHeaderDelegate({required this.child, required this.maxHeight, required this.minHeight});
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);
  @override double get maxExtent => maxHeight;
  @override double get minExtent => minHeight;
  @override bool shouldRebuild(_StickyHeaderDelegate oldDelegate) => maxHeight != oldDelegate.maxExtent || minHeight != oldDelegate.minExtent || child != oldDelegate.child;
}