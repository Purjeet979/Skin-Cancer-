import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  TTSService() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("hi-IN"); // Hindi (India)
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.85); // Calm, deliberate speech rate for medical clarity
      _isInitialized = true;
    } catch (e) {
      print("TTS initialization notice: $e");
    }
  }

  Future<void> speakGuidance(String promptKey) async {
    if (!_isInitialized) await _initTts();

    Map<String, String> hindiPrompts = {
      'welcome': 'डरमास्कैन एआई में आपका स्वागत है। कृपया त्वचा के प्रभावित स्थान को कैमरे के केंद्र में रखें।',
      'align': 'कृपया कैमरे को 10 सेंटीमीटर की दूरी पर स्थिर रखें और अच्छी रोशनी सुनिश्चित करें।',
      'capturing': 'फ़ोटो खींची जा रही है, कृपया स्थिर रहें।',
      'complete': 'स्कैन पूर्ण हो गया है। आपका ऑफ़लाइन परिणाम तैयार है।',
      'suspicious_alert': 'सावधानी: यह स्थिति आगे की जांच के योग्य है। हम आपको विशेषज्ञ त्वचा विशेषज्ञ से परामर्श की सलाह देते हैं।'
    };

    String text = hindiPrompts[promptKey] ?? promptKey;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
