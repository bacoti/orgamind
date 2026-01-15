import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/api_config.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

class ParticipantQrScreen extends StatefulWidget {
  final int eventId;
  const ParticipantQrScreen({super.key, required this.eventId});

  @override
  State<ParticipantQrScreen> createState() => _ParticipantQrScreenState();
}

class _ParticipantQrScreenState extends State<ParticipantQrScreen> {
  String? token;
  String? err;

  Future<void> _load() async {
    final auth = AuthService();
    await auth.init();
    final t = auth.getToken();
    if (t == null) {
      setState(() => err = 'Token tidak ditemukan (silakan login ulang)');
      return;
    }

    try {
      final r = await http.get(
        Uri.parse(ApiConfig.attendanceQrToken(widget.eventId)),
        headers: ApiConfig.getHeaders(token: t),
      );
      final data = jsonDecode(r.body);
      if (r.statusCode == 200 && data['success'] == true) {
        setState(() {
          token = data['data']['token'];
          err = null;
        });
      } else {
        setState(() => err = data['message'] ?? 'Gagal ambil token');
      }
    } catch (e) {
      setState(() => err = 'Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Kehadiran')),
      body: Center(
        child: err != null
            ? Text(err!)
            : token == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(data: token!, size: 280),
                      const SizedBox(height: 12),
                      const Text('Tunjukkan QR ini ke admin untuk discan.'),
                    ],
                  ),
      ),
    );
  }
}
