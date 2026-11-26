import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef VoiceCommandCallback = Future<void> Function(String command);
typedef VoiceSessionChanged = void Function(bool active);

class VoiceAssistantService {
  VoiceAssistantService._();

  static final VoiceAssistantService instance = VoiceAssistantService._();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _isListening = false;
  bool _sessionActive = false;
  bool _processingCommand = false;
  VoiceCommandCallback? _onCommand;
  VoiceSessionChanged? _onSessionChanged;

  void _notifySessionChanged() {
    _onSessionChanged?.call(_sessionActive);
  }

  bool get isListening => _isListening;
  bool get isSessionActive => _sessionActive;

  Future<bool> initialize() async {
    if (_initialized) return true;

    final available = await _speech.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
        // Si el reconocimiento termina por silencio o timeout, cerrar la sesión.
        // Cuando hay una frase final, _processCommand se encarga del cierre.
        if (status == 'done' && _sessionActive && !_processingCommand) {
          _sessionActive = false;
          _isListening = false;
          _notifySessionChanged();
        }
      },
      onError: (_) {
        _isListening = false;
        _sessionActive = false;
        _notifySessionChanged();
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
    VoiceSessionChanged? onSessionChanged,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('immersive_voice_assistant_enabled') ?? false;
    if (!enabled) return false;

    final available = await initialize();
    if (!available) return false;

    if (_sessionActive) {
      _onCommand = onCommand;
      _onSessionChanged = onSessionChanged;
      return _listenOnce();
    }

    _onCommand = onCommand;
    _onSessionChanged = onSessionChanged;
    _sessionActive = true;
    _notifySessionChanged();
    final started = await _listenOnce();
    if (!started && !_speech.isListening) {
      _sessionActive = false;
      _isListening = false;
      _notifySessionChanged();
    }
    return started;
  }

  Future<bool> _listenOnce() async {
    if (!_sessionActive) return false;
    if (_processingCommand || _speech.isListening) return true;

    try {
      await _speech.listen(
      localeId: 'es_MX',
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) {
        if (result.finalResult &&
            result.recognizedWords.trim().isNotEmpty &&
            !_processingCommand) {
          _processCommand(result.recognizedWords.trim().toLowerCase());
        }
      },
      );
      _isListening = _speech.isListening;
      return true;
    } catch (_) {
      _isListening = false;
      _sessionActive = false;
      _notifySessionChanged();
      return false;
    }
  }

  Future<void> _processCommand(String command) async {
    if (_processingCommand) return;
    _processingCommand = true;

    // Comportamiento tipo buscador: cerrar el micrófono al detectar la frase
    // final y antes de ejecutar la consulta o reproducir la respuesta.
    _sessionActive = false;
    _isListening = false;
    _notifySessionChanged();
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {
        // La consulta debe poder procesarse aunque el plugin ya haya detenido el audio.
      }
    }

    try {
      await _onCommand?.call(command);
    } catch (_) {
      // Un fallo al ejecutar un comando no debe dejar el estado de voz bloqueado.
    } finally {
      _processingCommand = false;
    }
  }

  Future<void> stopListening() async {
    _sessionActive = false;
    _isListening = false;
    _notifySessionChanged();
    if (_speech.isListening) await _speech.stop();
  }

  Future<void> speak(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('immersive_voice_assistant_enabled') ?? false;
    if (!enabled || message.trim().isEmpty) return;

    if (_speech.isListening) await _speech.stop();
    _isListening = false;
    await initialize();
    await _tts.stop();
    await _tts.speak(message);
  }

  Future<void> dispose() async {
    await stopListening();
    await _tts.stop();
    _onCommand = null;
    _onSessionChanged = null;
  }
}
