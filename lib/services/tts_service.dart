// Crear archivo: lib/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();

      // Configuración básica
      await _flutterTts.setLanguage("es-EC"); // Español
      await _flutterTts.setSpeechRate(0.65); // Velocidad normal
      await _flutterTts.setVolume(1.0); // Volumen máximo
      await _flutterTts.setPitch(1.0); // Tono normal

      // Listeners para controlar estado
      _flutterTts.setStartHandler(() {
        print('🔊 Iniciando reproducción de audio');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        print('✅ Audio completado');
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        print('❌ Error TTS: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('🎤 TTS Service inicializado correctamente');

    } catch (e) {
      print('❌ Error inicializando TTS: $e');
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      print('❌ TTS no disponible');
      return;
    }

    try {
      // Detener audio actual si está reproduciéndose
      if (_isSpeaking) {
        await stop();
      }

      print('🔊 Reproduciendo: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      await _flutterTts.speak(text);

    } catch (e) {
      print('❌ Error reproduciendo audio: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      print('⏸️ Audio detenido');
    } catch (e) {
      print('❌ Error deteniendo audio: $e');
    }
  }

  Future<void> pause() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.pause();
      print('⏸️ Audio pausado');
    } catch (e) {
      print('❌ Error pausando audio: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _flutterTts.stop();
      _isInitialized = false;
      _isSpeaking = false;
    }
  }
}