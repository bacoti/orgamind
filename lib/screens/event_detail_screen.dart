// lib/screens/event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.event.status ?? 'unknown';
    _scrollController.addListener(() {
      if (_scrollController.offset > 150 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 150 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollContgitroller.dispose();
    super.dispose();
  }

  // --- LOGIKA FORMAT WAKTU (Mulai - Selesai) ---
  String _getFormattedTime() {
    String formatHHmm(String t) {
      try {
        final parts = t.split(':');
        return "${parts[0]}:${parts[1]}"; // Ambil HH:mm
      } catch (e) {
        return t;
      }
    }

    final start = formatHHmm(widget.event.time);

    if (widget.event.endTime != null && widget.event.endTime!.isNotEmpty) {
      final end = formatHHmm(widget.event.endTime!);
      if (start == end) return "$start WIB";
      return "$start - $end WIB";
    }

    return "$start WIB";
  }

  Future<void> _handleInvitationResponse(String action) async {
    setState(() => _isProcessing = true);
    try {
      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();

      if (token != null && mounted) {
        final success = await Provider.of<EventProvider>(
          context,
          listen: false,
        ).respondToInvitation(widget.event.id, action, token);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  action == 'accept'
                      ? 'Undangan diterima!'
                      : 'Undangan ditolak',
                ),
                backgroundColor: action == 'accept' ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal memproses permintaan'),
                backgroundColor: Colors.red,
              ),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    final showActionButtons = _currentStatus == 'invited' && !isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // --- 1. HEADER IMAGE ---
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: _isScrolled
                        ? Colors.white
                        : Colors.black.withOpacity(0.3),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: _isScrolled ? Colors.black : Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.event.imageUrl != null
                          ? Image.network(
                              widget.event.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          // --- PERBAIKAN DI SINI (Background Biru) ---
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  // Menggunakan warna primary dan variasinya agar tetap biru
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: -50,
                                    right: -50,
                                    child: CircleAvatar(
                                      radius: 100,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 50,
                                    left: -30,
                                    child: CircleAvatar(
                                      radius: 80,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Icon(
                                      Icons.event_seat_rounded,
                                      size: 80,
                                      color: Colors.white30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      // -------------------------------------------
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.event.category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.event.category!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.event.location,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 2. KONTEN DETAIL ---
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ROW INFO: TANGGAL & WAKTU ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoBox(
                                icon: Icons.calendar_today_rounded,
                                title: 'Tanggal',
                                value: DateFormat(
                                  'dd MMM yyyy',
                                  'id_ID',
                                ).format(widget.event.date),
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoBox(
                                icon: Icons.access_time_rounded,
                                title: 'Waktu',
                                value: _getFormattedTime(),
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- ORGANIZER ---
                        const Text(
                          'Diselenggarakan oleh',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  (widget.event.organizerName ?? 'A')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.event.organizerName ?? 'Panitia Acara',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  'Organizer Terverifikasi',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (!isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    _currentStatus,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _translateStatus(_currentStatus),
                                  style: TextStyle(
                                    color: _getStatusColor(_currentStatus),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 24),

                        // --- DESKRIPSI ---
                        const Text(
                          'Tentang Acara',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event.description,
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- ADMIN ACTIONS ---
                        if (isAdmin)
                          Column(
                            children: [
                              _buildAdminActionButton(
                                icon: Icons.people_alt_rounded,
                                label: 'Lihat Daftar Peserta',
                                color: AppColors.primary,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParticipantListScreen(
                                      eventId: widget.event.id,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAdminActionButton(
                                icon: Icons.person_add_rounded,
                                label: 'Undang Peserta Baru',
                                color: Colors.teal,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        InviteParticipantsScreen(
                                          eventId: widget.event.id.toString(),
                                          eventTitle: widget.event.title,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (showActionButtons && !isAdmin)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _handleInvitationResponse('reject'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                foregroundColor: Colors.grey.shade700,
                              ),
                              child: const Text(
                                'Tolak',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _handleInvitationResponse('accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: AppColors.primary.withOpacity(0.4),
                                elevation: 8,
                              ),
                              child: const Text(
                                'Terima Undangan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
            ],
          ),
        ),
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
    if (status == 'registered') return 'Terdaftar';
    if (status == 'invited') return 'Menunggu Konfirmasi';
    if (status == 'rejected') return 'Undangan Ditolak';
    return status;
  }
}
