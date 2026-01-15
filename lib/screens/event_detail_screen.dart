// lib/screens/event_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import '../constants/theme.dart';
import '../constants/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
import 'invite_participants_screen.dart';
import 'participant_list_screen.dart';
import 'home_screen.dart';

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
    _scrollController.dispose();
    super.dispose();
  }

  String _getFormattedTime() {
    String formatHHmm(String t) {
      try {
        final parts = t.split(':');
        return "${parts[0]}:${parts[1]}";
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
            setState(() {
              _currentStatus = action == 'accept' ? 'registered' : 'rejected';
            });

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

  /// Menampilkan dialog QR Code untuk presensi event (Admin Only)
  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'QR Code Presensi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _QrCodeWidget(eventId: widget.event.id),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peserta yang terdaftar dapat scan QR ini untuk presensi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    final showActionButtons = (_currentStatus == 'invited') && !isAdmin;
    final showQrButton = (_currentStatus == 'registered') && !isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
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
                        : Colors.black.withValues(alpha: 0.3),
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
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.7),
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
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 50,
                                    left: -30,
                                    child: CircleAvatar(
                                      radius: 80,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.1,
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
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
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
                                  ).withValues(alpha: 0.1),
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
                                icon: Icons.qr_code_2_rounded,
                                label: 'Tampilkan QR Presensi',
                                color: Colors.indigo,
                                onTap: () => _showQrCodeDialog(),
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
                      color: Colors.black.withValues(alpha: 0.1),
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
                                shadowColor: AppColors.primary.withValues(
                                  alpha: 0.4,
                                ),
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

          if (showQrButton && !isAdmin)
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigasi ke HomeScreen dengan tab Pemindai (index 1)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(initialIndex: 1),
                        ),
                        (route) => false, // Hapus semua route sebelumnya
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text(
                      'Scan QR Presensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
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
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
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
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
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
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5),
              ),
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

/// Widget untuk menampilkan QR Code event (digunakan oleh admin)
class _QrCodeWidget extends StatefulWidget {
  final int eventId;
  const _QrCodeWidget({required this.eventId});

  @override
  State<_QrCodeWidget> createState() => _QrCodeWidgetState();
}

class _QrCodeWidgetState extends State<_QrCodeWidget> {
  String? _qrData;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQrData();
  }

  Future<void> _generateQrData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();

      if (token == null) {
        setState(() {
          _error = 'Sesi habis, silakan login ulang';
          _isLoading = false;
        });
        return;
      }

      // Admin: Generate QR Code event menggunakan endpoint baru
      final response = await http.get(
        Uri.parse(ApiConfig.eventQrCode(widget.eventId)),
        headers: ApiConfig.getHeaders(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _qrData = data['data']['token'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Gagal generate QR Code';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _generateQrData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        QrImageView(
          data: _qrData!,
          version: QrVersions.auto,
          size: 200,
          backgroundColor: Colors.white,
          errorStateBuilder: (ctx, err) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Event ID: ${widget.eventId}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
