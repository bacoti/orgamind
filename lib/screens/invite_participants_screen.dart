// lib/screens/invite_participants_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';

class InviteParticipantsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const InviteParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<InviteParticipantsScreen> createState() =>
      _InviteParticipantsScreenState();
}

class _InviteParticipantsScreenState extends State<InviteParticipantsScreen> {
  // Menyimpan ID yang BARU dipilih untuk diundang
  final Set<String> _selectedUserIds = {};

  // Menyimpan ID user yang SUDAH diundang sebelumnya (dari database)
  Set<String> _alreadyInvitedIds = {};

  bool _isInit = true;
  bool _isLoadingData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadData();
      _isInit = false;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      final authService = AuthService();
      await authService.init();
      final token = authService.getToken();

      if (!mounted) return;

      // 1. Load semua user dengan role 'participant'
      await userProvider.getAllUsers(role: 'participant');

      if (!mounted) return;

      // 2. Load peserta yang sudah ada di event ini (untuk difilter)
      if (token != null) {
        // Parse eventId ke int karena provider butuh int
        final int eventIdInt = int.tryParse(widget.eventId) ?? 0;

        if (eventIdInt != 0) {
          final existingParticipants = await eventProvider.getEventParticipants(
            eventIdInt,
            token,
          );

          if (!mounted) return;

          // Masukkan ID mereka ke set _alreadyInvitedIds
          // Pastikan dikonversi ke String agar cocok dengan user.id
          setState(() {
            _alreadyInvitedIds = existingParticipants
                .map((p) => p['id'].toString())
                .toSet();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading invite data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _submitInvite() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu peserta')),
      );
      return;
    }

    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();

    if (!mounted) return;

    if (token != null) {
      // KONVERSI ID STRING KE INT UNTUK DIKIRIM KE API
      List<int> userIdsInt = _selectedUserIds
          .map((id) => int.tryParse(id) ?? 0)
          .where((id) => id != 0)
          .toList();

      final success = await Provider.of<EventProvider>(
        context,
        listen: false,
      ).inviteParticipants(widget.eventId, userIdsInt, token);

      if (!mounted) return;

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Peserta berhasil diundang!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Kembali dan refresh
        } else {
          final errorMessage = Provider.of<EventProvider>(
            context,
            listen: false,
          ).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Gagal mengundang peserta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Undang Peserta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final users = userProvider.users;

                if (users.isEmpty) {
                  return const Center(child: Text('Belum ada user terdaftar.'));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Pilih peserta untuk event "${widget.eventTitle}"',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];

                          // Cek apakah user ini sudah pernah diundang
                          final isAlreadyInvited = _alreadyInvitedIds.contains(
                            user.id,
                          );

                          // Cek apakah user ini sedang dipilih (dicentang)
                          final isSelected = _selectedUserIds.contains(user.id);

                          return CheckboxListTile(
                            // Jika sudah diundang, checkbox otomatis true tapi disabled
                            value: isAlreadyInvited ? true : isSelected,

                            // Jika sudah diundang, matikan interaksi (onChanged: null)
                            onChanged: isAlreadyInvited
                                ? null
                                : (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedUserIds.add(user.id);
                                      } else {
                                        _selectedUserIds.remove(user.id);
                                      }
                                    });
                                  },
                            activeColor: isAlreadyInvited
                                ? Colors.grey
                                : AppColors.primary,
                            title: Row(
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isAlreadyInvited
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                if (isAlreadyInvited)
                                  const Text(
                                    ' (Sudah diundang)',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(user.email),
                            secondary: CircleAvatar(
                              backgroundColor: isAlreadyInvited
                                  ? Colors.grey.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: isAlreadyInvited
                                      ? Colors.grey
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _selectedUserIds.isNotEmpty ? _submitInvite : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Undang (${_selectedUserIds.length}) Peserta',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
