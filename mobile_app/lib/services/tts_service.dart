import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  String _currentLanguage = 'hi'; // 'hi' or 'en'

  TTSService() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  String get currentLanguage => _currentLanguage;

  Future<void> setLanguage(String lang) async {
    _currentLanguage = lang;
    try {
      if (lang == 'en') {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setSpeechRate(0.45);
      } else {
        await _flutterTts.setLanguage("hi-IN");
        await _flutterTts.setSpeechRate(0.40);
      }
    } catch (e) {
      print("TTS setLanguage notice: $e");
    }
  }

  Future<void> _initTts() async {
    try {
      await setLanguage(_currentLanguage);
      await _flutterTts.setPitch(1.0);
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
      'complete': 'स्कैन पूर्ण हो गया है। आपका परिणाम तैयार है।',
      'invalid_skin': 'चित्र में मानव त्वचा नहीं पाई गई। कृपया त्वचा की साफ़ फ़ोटो खींचें।',
      'suspicious_alert': 'सावधानी: यह स्थिति आगे की जांच के योग्य है। हम आपको विशेषज्ञ त्वचा विशेषज्ञ से परामर्श की सलाह देते हैं।'
    };

    Map<String, String> englishPrompts = {
      'welcome': 'Welcome to DermaScan AI. Please align the skin area in the center of the camera.',
      'align': 'Please keep the camera steady at 10 centimeters distance with good lighting.',
      'capturing': 'Capturing photo, please hold steady.',
      'complete': 'Scan complete. Your analysis result is ready.',
      'invalid_skin': 'No human skin detected in the image. Please capture a clear skin photo.',
      'suspicious_alert': 'Caution: This condition requires further evaluation by a specialist dermatologist.'
    };

    Map<String, String> prompts = _currentLanguage == 'en' ? englishPrompts : hindiPrompts;
    String text = prompts[promptKey] ?? promptKey;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
