import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img_lib;
import '../services/tflite_service.dart';
import '../services/tts_service.dart';
import 'result_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({Key? key}) : super(key: key);

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with WidgetsBindingObserver {
  final TTSService _ttsService = TTSService();
  final TFLiteService _tfLiteService = TFLiteService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _cameraErrorMessage = "";

  bool _isProcessing = false;
  String _statusText = "कैमरा तैयार है (Camera is Ready)";
  String _currentLanguage = "hi"; // 'hi' or 'en'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tfLiteService.loadModel();
    _ttsService.speakGuidance('welcome');
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        int backCamIndex = _cameras!.indexWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backCamIndex != -1 ? backCamIndex : 0;
        await _onNewCameraSelected(_cameras![_selectedCameraIndex]);
      } else {
        setState(() {
          _isCameraError = true;
          _cameraErrorMessage = "No camera hardware detected.";
        });
      }
    } catch (e) {
      setState(() {
        _isCameraError = true;
        _cameraErrorMessage = "Camera permission or initialization error: $e";
      });
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraError = true;
          _cameraErrorMessage = "Camera error: $e";
        });
      }
    }
  }

  Future<void> _captureRealImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
        _statusText = _currentLanguage == 'hi'
            ? "फ़ोटो की जाँच हो रही है..."
            : "Analyzing photo...";
      });

      await _ttsService.speakGuidance('capturing');
      final XFile photo = await _cameraController!.takePicture();
      final File imgFile = File(photo.path);

      await _processImageAndNavigate(imgFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capture Error: $e")),
      );
      setState(() {
        _isProcessing = false;
        _statusText = "कैमरा तैयार है (Camera is Ready)";
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _isProcessing = true;
          _statusText = _currentLanguage == 'hi'
              ? "गैलरी फ़ोटो की जाँच हो रही है..."
              : "Analyzing gallery photo...";
        });

        await _ttsService.speakGuidance('capturing');
        final File imgFile = File(image.path);
        await _processImageAndNavigate(imgFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gallery Upload Error: $e")),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImageAndNavigate(File imgFile) async {
    try {
      final result = await _tfLiteService.classifyImage(imgFile);
      if (result.riskLevel == 'INVALID') {
        await _ttsService.speakGuidance('invalid_skin');
      } else {
        await _ttsService.speakGuidance('complete');
      }

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
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = "ऑफ़लाइन मोड में तैयार (Zero Internet Required)";
        });
      }
    }
  }

  Future<void> _simulateCapture(String sampleType) async {
    if (_isProcessing) return;
    try {
      setState(() {
        _isProcessing = true;
        _statusText = "ऑफ़लाइन TFLite मॉडल द्वारा विश्लेषण किया जा रहा है...";
      });

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/captured_$sampleType.jpg');

      final sampleImg = img_lib.Image(width: 400, height: 400);
      for (int y = 0; y < 400; y++) {
        for (int x = 0; x < 400; x++) {
          sampleImg.setPixelRgb(x, y, 200, 140, 120);
        }
      }
      final jpgBytes = img_lib.encodeJpg(sampleImg);
      await file.writeAsBytes(jpgBytes);

      await _processImageAndNavigate(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sample Error: $e")),
      );
      setState(() {
        _isProcessing = false;
        _statusText = "ऑफ़लाइन मोड में तैयार (Zero Internet Required)";
      });
    }
  }

  void _toggleLanguage() {
    String nextLang = _currentLanguage == 'hi' ? 'en' : 'hi';
    setState(() {
      _currentLanguage = nextLang;
    });
    _ttsService.setLanguage(nextLang);
    _ttsService.speakGuidance('welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DermaScan AI — Live Camera"),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          // Voice Language Toggle Button
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.amberAccent),
            icon: const Icon(Icons.translate, size: 18),
            label: Text(
              _currentLanguage == 'hi' ? "🇮🇳 HI" : "🇬🇧 EN",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _toggleLanguage,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.tealAccent),
            tooltip: "Voice Guidance",
            onPressed: () => _ttsService.speakGuidance('align'),
          ),
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.tealAccent),
              onPressed: () {
                _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
                _onNewCameraSelected(_cameras![_selectedCameraIndex]);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              // Empty space to replace the form
              const SizedBox(height: 8),

              // Camera Viewfinder Frame
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.6), width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Live Camera View or Fallback
                        if (_isCameraInitialized && _cameraController != null)
                          Positioned.fill(
                            child: AspectRatio(
                              aspectRatio: _cameraController!.value.aspectRatio,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        else if (_isCameraError)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.redAccent),
                                  const SizedBox(height: 12),
                                  Text(
                                    _cameraErrorMessage,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Retry Camera Access"),
                                    onPressed: _initCamera,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(color: Colors.tealAccent),
                          ),

                        // Overlay Reticle Guide
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.tealAccent.withOpacity(0.4), width: 1.5),
                            ),
                            margin: const EdgeInsets.all(40),
                          ),
                        ),

                        // Center Guidance Text Overlay
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _statusText,
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        if (_isProcessing)
                          Container(
                            color: Colors.black87,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.tealAccent),
                                  SizedBox(height: 16),
                                  Text(
                                    "Analyzing Lesion with On-Device AI...",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Voice Guidance Button & Language Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.record_voice_over, color: Colors.amberAccent, size: 20),
                  label: Text(
                    _currentLanguage == 'hi' ? "हिंदी वॉइस गाइडेंस (Hindi Voice)" : "English Voice Guidance (EN)",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onPressed: () => _ttsService.speakGuidance('welcome'),
                ),
              ),
              const SizedBox(height: 8),

              // Capture Controls, Gallery Upload & Sample Fallbacks
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Upload Image from Gallery
                    Flexible(
                      child: FittedBox(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.tealAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.photo_library, size: 18),
                          onPressed: _pickImageFromGallery,
                          label: const Text("Upload Photo", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    FloatingActionButton(
                      backgroundColor: Colors.tealAccent,
                      onPressed: _captureRealImage,
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
                    ),
                    const SizedBox(width: 24),
                    Flexible(
                      child: FittedBox(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.transparent,
                            side: const BorderSide(color: Colors.transparent),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.science, size: 18, color: Colors.transparent),
                          onPressed: null,
                          label: const Text("Sample MEL", style: TextStyle(fontSize: 12, color: Colors.transparent)),
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
}

