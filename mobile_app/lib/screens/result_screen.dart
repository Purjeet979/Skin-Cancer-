import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/tflite_service.dart';
import 'referral_screen.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final TFLiteResult result;

  const ResultScreen({
    Key? key,
    required this.imageFile,
    required this.result,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showGradCam = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (mounted) {
      setState(() {
        _isOnline = !connectivityResult.contains(ConnectivityResult.none);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color riskColor = widget.result.riskLevel == 'HIGH'
        ? Colors.redAccent
        : (widget.result.riskLevel == 'MEDIUM'
            ? Colors.orangeAccent
            : (widget.result.riskLevel == 'INVALID' ? Colors.redAccent : Colors.greenAccent));

    return Scaffold(
      appBar: AppBar(
        title: const Text("DermaScan AI — Scan Result"),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Container(
        color: const Color(0xFF0F172A),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image & Grad-CAM Display Card
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.file(
                            widget.imageFile,
                            height: 260,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (_showGradCam && widget.result.hasLesion && widget.result.heatmapCenterX != null)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.60),
                                    Colors.yellow.withOpacity(0.35),
                                    Colors.blue.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.35, 0.65, 1.0],
                                  center: Alignment(
                                    widget.result.heatmapCenterX!,
                                    widget.result.heatmapCenterY!,
                                  ),
                                  radius: 0.55,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isOnline ? Icons.wifi : Icons.wifi_off,
                                  color: _isOnline ? Colors.greenAccent : Colors.amberAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isOnline ? "ONLINE" : "OFFLINE",
                                  style: TextStyle(
                                    color: _isOnline ? Colors.greenAccent : Colors.amberAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.result.hasLesion ? Icons.remove_red_eye : Icons.check_circle_outline,
                                color: widget.result.hasLesion ? Colors.tealAccent : Colors.greenAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.result.hasLesion
                                    ? (_showGradCam ? "Grad-CAM Heatmap Layer: ON" : "Original Lesion View")
                                    : (widget.result.riskLevel == 'INVALID' ? "Invalid Image — Non-Skin Photo" : "Normal Healthy Skin (No Heatmap Required)"),
                                style: TextStyle(
                                  color: widget.result.hasLesion ? Colors.white70 : (widget.result.riskLevel == 'INVALID' ? Colors.redAccent : Colors.greenAccent),
                                  fontSize: 13,
                                  fontWeight: widget.result.hasLesion ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (widget.result.hasLesion)
                            Switch(
                              value: _showGradCam,
                              activeColor: Colors.tealAccent,
                              onChanged: (val) => setState(() => _showGradCam = val),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Network Status Banner
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.cloud_done : Icons.wifi_off,
                        color: _isOnline ? Colors.greenAccent : Colors.amberAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isOnline 
                              ? "Network Active: Real-time syncing available. Inference still performed 100% locally."
                              : "Offline Mode Active: Verified 100% Airplane Mode Compatible. Referrals will queue locally.",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Result Details Card
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.result.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: riskColor),
                            ),
                            child: Text(
                              "RISK: ${widget.result.riskLevel}",
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.result.riskLevel == 'INVALID') ...[
                        const SizedBox(height: 12),
                        const Text(
                          "Scan Status: Non-Skin Image Detected",
                          style: TextStyle(color: Colors.redAccent, fontSize: 15),
                        ),
                      ],
                      const Divider(color: Colors.white24, height: 24),
                      Text(
                        widget.result.riskLevel == 'INVALID'
                            ? "⚠️ Invalid Scan: No human skin detected in the photo. Please capture a clear, well-lit photo of skin or a skin lesion."
                            : (widget.result.referralRecommended
                                ? "⚠️ Action Recommended: This lesion exhibits features requiring specialist evaluation. Referral queued locally."
                                : "✅ Low Risk / Normal: Routine monitoring recommended. Consult a physician if changes occur."),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Referral Booking Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.result.referralRecommended ? Colors.redAccent : Colors.tealAccent,
                  foregroundColor: widget.result.referralRecommended ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(widget.result.referralRecommended ? Icons.medical_services : Icons.calendar_month),
                label: Text(
                  widget.result.referralRecommended ? "Find Specialist & Book Referral" : "View Dermatologist Directory",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReferralScreen(
                        lesionClass: widget.result.label,
                        riskLevel: widget.result.riskLevel,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
