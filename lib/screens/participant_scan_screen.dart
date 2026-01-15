// lib/screens/participant_scan_screen.dart
// Screen untuk peserta scan QR event untuk presensi

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/api_config.dart';
import '../constants/theme.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

class ParticipantScanScreen extends StatefulWidget {
  final int? eventId; // Optional: jika dari detail event
  final String? eventTitle;

  const ParticipantScanScreen({
    super.key,
    this.eventId,
    this.eventTitle,
  });

  @override
  State<ParticipantScanScreen> createState() => _ParticipantScanScreenState();
}

class _ParticipantScanScreenState extends State<ParticipantScanScreen> {
  bool _isBusy = false;
  bool _isSuccess = false;
  bool _isCameraReady = false;
  String? _message;
  String? _cameraError;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      // Start the scanner
      await _scannerController!.start();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Gagal mengakses kamera: $e';
          _isCameraReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetected(String qrData) async {
    if (_isBusy || _isSuccess) return;

    setState(() {
      _isBusy = true;
      _message = null;
    });

    final authService = AuthService();
    await authService.init();
    final token = authService.getToken();

    if (token == null) {
      setState(() {
        _message = 'Sesi habis, silakan login ulang';
        _isBusy = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.participantScan),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({'token': qrData}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isSuccess = true;
          _message = data['message'] ?? 'Presensi berhasil!';
        });

        // Tunggu sebentar lalu kembali
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true); // Return true untuk refresh
        }
      } else {
        setState(() {
          _message = data['message'] ?? 'Gagal melakukan presensi';
          _isBusy = false;
        });

        // Reset setelah beberapa detik agar bisa scan ulang
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _message = null);
        }
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.eventTitle ?? 'Scan QR Presensi',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          // Tombol untuk switch kamera (jika ada multiple camera)
          if (_isCameraReady && _scannerController != null)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: () => _scannerController!.switchCamera(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Jika ada error kamera
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off,
                size: 80,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                _cameraError!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pastikan browser memiliki izin akses kamera',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Jika kamera belum siap
    if (!_isCameraReady || _scannerController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Mempersiapkan kamera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // Kamera siap - tampilkan scanner
    return Stack(
      children: [
        // Scanner
        MobileScanner(
          controller: _scannerController!,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;
            final rawValue = barcodes.first.rawValue;
            if (rawValue != null) {
              _handleQrDetected(rawValue);
            }
          },
          errorBuilder: (context, error, child) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${error.errorCode.name}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.errorDetails?.message ?? 'Unknown error',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Overlay dengan scan area indicator
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isSuccess ? Colors.green : AppColors.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Status overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isBusy && !_isSuccess)
                    const CircularProgressIndicator(color: Colors.white),
                  if (_isSuccess)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            _message ?? 'Berhasil!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_message != null && !_isSuccess)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _message!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!_isBusy && _message == null)
                    Column(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Arahkan kamera ke QR Code event',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'QR Code ditampilkan oleh admin/panitia',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      );
  }
}
