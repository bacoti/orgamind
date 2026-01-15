import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/api_config.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool busy = false;
  String? lastMsg;

  Future<void> _submitToken(String token) async {
    if (busy) return;
    setState(() => busy = true);

    final auth = AuthService();
    await auth.init();
    final t = auth.getToken();
    if (t == null) {
      setState(() {
        lastMsg = 'Token tidak ada (login ulang)';
        busy = false;
      });
      return;
    }

    try {
      final r = await http.post(
        Uri.parse(ApiConfig.attendanceScan),
        headers: ApiConfig.getHeaders(token: t),
        body: jsonEncode({'token': token}),
      );
      final data = jsonDecode(r.body);
      setState(() {
        lastMsg = data['message'] ?? (data['success'] == true ? 'OK' : 'Gagal');
      });
    } catch (e) {
      setState(() => lastMsg = 'Error: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Kehadiran')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final raw = barcodes.first.rawValue;
                if (raw != null) _submitToken(raw);
              },
            ),
          ),
          if (lastMsg != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(lastMsg!, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
