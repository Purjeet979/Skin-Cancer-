import 'package:flutter/material.dart';
import '../services/offline_queue_service.dart';

class ReferralScreen extends StatefulWidget {
  final String lesionClass;
  final String riskLevel;

  const ReferralScreen({
    Key? key,
    required this.lesionClass,
    required this.riskLevel,
  }) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final OfflineQueueService _queueService = OfflineQueueService();
  final _nameController = TextEditingController(text: "Rahul Sharma (Demo Patient)");
  final _contactController = TextEditingController(text: "+91 98765 43210 | rahul@example.com");

  bool _isOnline = false;
  int _selectedDoctorId = 1;
  String _statusMessage = "";
  bool _isSubmitting = false;

  // Mock / Seed Dermatologist Directory Dataset (Explicitly Labeled)
  final List<Map<String, dynamic>> _mockDoctors = [
    {
      "id": 1,
      "name": "Dr. Sarah Lin, MD (Mock Profile)",
      "specialty": "Dermato-Oncology & Melanoma",
      "clinic": "Metro Skin Cancer Center (Mock)",
      "distance_km": "0.8 km",
      "rating": "4.9 ★"
    },
    {
      "id": 2,
      "name": "Dr. Marcus Vance, MD (Mock Profile)",
      "specialty": "Mohs Surgery & Skin Cancer",
      "clinic": "City Skin Institute (Mock)",
      "distance_km": "1.4 km",
      "rating": "4.8 ★"
    },
    {
      "id": 3,
      "name": "Dr. Elena Rostova, MD (Mock Profile)",
      "specialty": "General & Pediatric Dermatology",
      "clinic": "Bayview Medical (Mock)",
      "distance_km": "2.1 km",
      "rating": "4.7 ★"
    }
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    bool online = await _queueService.isOnline();
    setState(() {
      _isOnline = online;
    });
  }

  Future<void> _submitReferral() async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = "";
    });

    final booking = ReferralBooking(
      patientName: _nameController.text,
      patientContact: _contactController.text,
      dermatologistId: _selectedDoctorId,
      lesionClass: widget.lesionClass,
      riskLevel: widget.riskLevel,
    );

    final res = await _queueService.queueOrSendReferral(booking);

    setState(() {
      _isSubmitting = false;
      _statusMessage = res['message'];
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: [
              Icon(
                res['synced'] ? Icons.cloud_done : Icons.wifi_off,
                color: res['synced'] ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Text(
                res['synced'] ? "Booking Confirmed Online" : "Queued Offline",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            res['message'],
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.tealAccent)),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dermatologist Referral"),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Container(
        color: const Color(0xFF0F172A),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Online / Offline Status Chip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isOnline ? Colors.greenAccent : Colors.orangeAccent),
                ),
                child: Row(
                  children: [
                    Icon(_isOnline ? Icons.wifi : Icons.wifi_off, color: _isOnline ? Colors.greenAccent : Colors.orangeAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isOnline
                            ? "Online Mode: Direct server referral booking enabled."
                            : "Offline Mode: Referral will be queued in local SQLite DB and synced when online.",
                        style: TextStyle(
                          color: _isOnline ? Colors.greenAccent : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mock Dataset Disclaimer
              const Text(
                "NOTE: Dermatologist profiles are from a mock/seed dataset for demonstration purposes.",
                style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),

              // Doctor List Radio Selector
              const Text(
                "Select Nearest Specialist:",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ..._mockDoctors.map((doc) {
                bool isSelected = _selectedDoctorId == doc["id"];
                return Card(
                  color: isSelected ? const Color(0xFF334155) : const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? Colors.tealAccent : Colors.transparent),
                  ),
                  child: ListTile(
                    title: Text(doc["name"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("${doc["specialty"]} • ${doc["clinic"]}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(doc["distance_km"], style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                        Text(doc["rating"], style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedDoctorId = doc["id"];
                      });
                    },
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              // Form inputs
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Patient Name",
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Patient Contact (Phone/Email)",
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Referral Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                label: Text(
                  _isSubmitting ? "Processing..." : (_isOnline ? "Book Online Appointment" : "Queue Offline Referral"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSubmitting ? null : _submitReferral,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
