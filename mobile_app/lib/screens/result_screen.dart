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
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkNetwork();
  }

  String _getRednessLevel(double score) {
    if (score > 0.10) return "High (Possible bleeding/wound)";
    if (score > 0.02) return "Moderate";
    return "Low";
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
                    if (widget.result.riskLevel == 'INVALID' || !widget.result.hasLesion)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              widget.result.riskLevel == 'INVALID' ? Icons.error_outline : Icons.check_circle_outline,
                              color: widget.result.riskLevel == 'INVALID' ? Colors.redAccent : Colors.greenAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.result.riskLevel == 'INVALID' ? "Invalid Image — Non-Skin Photo" : "Normal Healthy Skin (No Lesion Detected)",
                                style: TextStyle(
                                  color: widget.result.riskLevel == 'INVALID' ? Colors.redAccent : Colors.greenAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                      const SizedBox(height: 12),
                      if (widget.result.riskLevel != 'INVALID')
                        Row(
                          children: [
                            const Icon(Icons.water_drop, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Surface Redness: ${_getRednessLevel(widget.result.rednessScore)}",
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
                        ),
                        child: const Text(
                          "Disclaimer: This tool screens for 7 specific skin lesion types from the HAM10000 dataset. It is not designed to assess open wounds, burns, or active bleeding — please consult a doctor directly for those.",
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
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
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  "Build Version: v1.0.3",
                  style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
