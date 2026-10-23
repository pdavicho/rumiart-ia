/// Constantes globales de la aplicación RumiArt IA.
/// NUNCA pongas API keys aquí. Las claves viven en el servidor o en GitHub Secrets.
class AppConstants {
  AppConstants._();

  // ── Backend de IA ──────────────────────────────────────────────────────────
  // La URL se inyecta en tiempo de build con --dart-define=AI_BACKEND_URL=...
  // En desarrollo apunta al servidor local; en release al servidor de Render.
  static const aiBackendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: 'https://rumiart-ia.onrender.com',
  );

  // ── ML Service ─────────────────────────────────────────────────────────────
  /// Umbral de confianza mínimo (0-255 para uint8). Equivale al 50%.
  static const int mlConfidenceThreshold = 128;

  /// Tamaño de entrada esperado por todos los modelos TFLite.
  static const int mlInputSize = 224;

  // ── Firestore ───────────────────────────────────────────────────────────────
  static const String artworksCollection = 'artworks';
  static const String recognitionLogsCollection = 'recognition_logs';

  // ── Hive ────────────────────────────────────────────────────────────────────
  static const String historyBox = 'history';
  static const String favoritesBox = 'favorites';

  /// Máximo de entradas en el historial local.
  static const int maxHistoryEntries = 50;
}
