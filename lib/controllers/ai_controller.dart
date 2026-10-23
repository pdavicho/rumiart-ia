import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Controlador GetX para el asistente IA.
/// Gestiona el historial de conversación y las llamadas al backend FastAPI+Gemini.
class AiController extends GetxController {
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  /// Lista de mensajes: [{'role': 'user'|'assistant', 'content': '...'}]
  final messages = <Map<String, String>>[].obs;

  /// Contexto de la obra actual (se setea desde HomeScreen tras un reconocimiento).
  final currentArtworkContext = ''.obs;

  /// Actualiza el contexto de obra para que el asistente responda en ese marco.
  void setArtworkContext({
    required String artworkName,
    required String artista,
    required String sala,
    required String descripcion,
  }) {
    currentArtworkContext.value =
        'Obra: $artworkName | Artista: $artista | Sala: $sala | '
        'Descripción: $descripcion';
  }

  /// Envía un mensaje al backend y agrega la respuesta al historial.
  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    // Agrega el mensaje del usuario
    messages.add({'role': 'user', 'content': userMessage.trim()});

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.aiBackendUrl}/chat'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'message': userMessage.trim(),
              'context': currentArtworkContext.value,
              'history': messages.take(10).toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['reply'] as String? ?? '(sin respuesta)';
        messages.add({'role': 'assistant', 'content': reply});
      } else {
        _setError('El asistente no está disponible (${response.statusCode}). Intenta de nuevo.');
      }
    } on Exception catch (e) {
      _setError(_mapError(e));
      // Elimina el mensaje del usuario si falló (opcional: déjalo para reenviar)
    } finally {
      isLoading.value = false;
    }
  }

  /// Limpia el historial y el contexto de obra.
  void clearConversation() {
    messages.clear();
    currentArtworkContext.value = '';
    hasError.value = false;
    errorMessage.value = '';
  }

  void _setError(String msg) {
    hasError.value = true;
    errorMessage.value = msg;
    debugPrint('AiController error: $msg');
  }

  String _mapError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('timeoutexception')) {
      return 'El asistente tardó demasiado. Intenta de nuevo.';
    }
    if (msg.contains('socket') || msg.contains('network') || msg.contains('connection')) {
      return 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
    }
    return 'Error al contactar al asistente. Intenta de nuevo.';
  }
}
