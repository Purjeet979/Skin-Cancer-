import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'capture_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('patient_name') ?? '';
      _contactController.text = prefs.getString('patient_contact') ?? '';
    });
  }

  Future<void> _startScan() async {
    if (_nameController.text.trim().isEmpty || _contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both name and contact details (नाम और मोबाइल नंबर दर्ज करें).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Save to shared_preferences so it doesn't ask again next time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patient_name', _nameController.text);
    await prefs.setString('patient_contact', _contactController.text);

    if (!mounted) return;
    
    // Dismiss keyboard before navigating
    FocusScope.of(context).unfocus();
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Custom App Logo
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Welcome Text
                const Text(
                  "DermaScan AI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your Personal Skin Health Assistant",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Description (User friendly)
                const Text(
                  "Easily analyze skin spots and lesions from the comfort of your home. Get instant, private results to help you decide if you should consult a doctor.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Patient Information Form
                const Text(
                  "Patient Details (मरीज़ की जानकारी)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white12,
                    hintText: "Patient Name (मरीज़ का नाम)",
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.tealAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white12,
                    hintText: "Contact Number (मोबाइल नंबर)",
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.tealAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                
                const SizedBox(height: 48),

                // Start Button
                ElevatedButton(
                  onPressed: _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Start Scan (स्कैन शुरू करें)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Privacy note
                const Text(
                  "Your photos and data never leave your device. 100% private and secure.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
