import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/tflite_service.dart';
import '../services/tts_service.dart';
import 'result_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({Key? key}) : super(key: key);

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final TTSService _ttsService = TTSService();
  final TFLiteService _tfLiteService = TFLiteService();
  bool _isProcessing = false;
  String _statusText = "ऑफ़लाइन मोड में तैयार (Zero Internet Required)";

  @override
  void initState() {
    super.initState();
    _tfLiteService.loadModel();
    _ttsService.speakGuidance('welcome');
  }

  Future<void> _processImageAndNavigate(File imgFile) async {
    setState(() {
      _isProcessing = true;
      _statusText = "ऑफ़लाइन TFLite मॉडल द्वारा विश्लेषण किया जा रहा है...";
    });

    await _ttsService.speakGuidance('capturing');

    try {
      // Execute local on-device inference using bundled .tflite model
      final result = await _tfLiteService.classifyImage(imgFile);
      await _ttsService.speakGuidance('complete');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imageFile: imgFile,
            result: result,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Analysis Error: $e")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
        _statusText = "ऑफ़लाइन मोड में तैयार (Zero Internet Required)";
      });
    }
  }

  Future<void> _simulateCapture(String sampleType) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/captured_$sampleType.jpg');

    // Create synthetic demo image bytes
    List<int> bytes = List.filled(400 * 400 * 3, 210);
    await file.writeAsBytes(bytes);

    _processImageAndNavigate(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DermaScan AI — Offline Capture"),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.tealAccent),
            tooltip: "Hindi Voice Guidance",
            onPressed: () => _ttsService.speakGuidance('align'),
          )
        ],
      ),
      body: Container(
        color: const Color(0xFF0F172A),
        child: Column(
          children: [
            // Offline Badge Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.green.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_off, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "100% OFFLINE INFERENCE (Bundled TFLite Model)",
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // Camera Viewfinder Simulation Frame
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.tealAccent.withOpacity(0.6), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.center_focus_strong, size: 100, color: Colors.tealAccent.withOpacity(0.8)),
                          const SizedBox(height: 16),
                          const Text(
                            "त्वचा के प्रभावित भाग को केंद्र में रखें",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusText,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black87,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.tealAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Voice Guidance Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.record_voice_over, color: Colors.amberAccent),
                label: const Text("हिंदी वॉइस गाइडेंस सुनें (Hindi Voice Guidance)", style: TextStyle(color: Colors.white)),
                onPressed: () => _ttsService.speakGuidance('welcome'),
              ),
            ),
            const SizedBox(height: 12),

            // Capture Controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent),
                    icon: const Icon(Icons.bug_report),
                    label: const Text("Sample MEL"),
                    onPressed: () => _simulateCapture('mel'),
                  ),
                  FloatingActionButton.large(
                    backgroundColor: Colors.tealAccent,
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 36),
                    onPressed: () => _simulateCapture('nevus'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Sample NV"),
                    onPressed: () => _simulateCapture('nv'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
