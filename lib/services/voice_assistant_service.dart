import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef VoiceCommandCallback = Future<void> Function(String command);

class VoiceAssistantService {
  VoiceAssistantService._();

  static final VoiceAssistantService instance = VoiceAssistantService._();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (_initialized) return true;

    final available = await _speech.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
      },
      onError: (_) {
        _isListening = false;
      },
    );

    if (!available) return false;

    await _tts.setLanguage('es-MX');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    _initialized = true;
    return true;
  }

  Future<bool> startListening({
    required VoiceCommandCallback onCommand,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('immersive_voice_assistant_enabled') ?? false;
    if (!enabled) return false;

    final available = await initialize();
    if (!available) return false;

    await _speech.listen(
      localeId: 'es_MX',
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          onCommand(result.recognizedWords.trim().toLowerCase());
        }
      },
    );
    _isListening = true;
    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) await _speech.stop();
    _isListening = false;
  }

  Future<void> speak(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('immersive_voice_assistant_enabled') ?? false;
    if (!enabled || message.trim().isEmpty) return;

    await stopListening();
    await initialize();
    await _tts.stop();
    await _tts.speak(message);
  }

  Future<void> dispose() async {
    await stopListening();
    await _tts.stop();
  }
}
