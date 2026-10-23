import 'package:get/get.dart';
import '../services/ml_service.dart';

/// Controlador GetX de la pantalla principal.
/// Migra toda la lógica que antes vivía en _HomeScreenState con setState.
class HomeController extends GetxController {
  // ── Estado reactivo ──────────────────────────────────────────────────────
  final currentRoom = 'sala1'.obs;
  final isInitializing = false.obs;
  final isProcessing = false.obs;
  final statusMessage = 'Selecciona una sala para comenzar'.obs;
  final recognitionResult = Rxn<RecognitionResult>();

  // ── Servicios ────────────────────────────────────────────────────────────
  final MLService _mlService = MLService();

  // ── Inicialización ───────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    initializeRoom('sala1');
  }

  @override
  void onClose() {
    _mlService.dispose();
    super.onClose();
  }

  // ── Salas ────────────────────────────────────────────────────────────────
  Future<void> initializeRoom(String roomId) async {
    if (isInitializing.value) return;

    isInitializing.value = true;
    statusMessage.value = 'Cargando sala...';
    recognitionResult.value = null;

    final success = await _mlService.initializeForRoom(roomId);

    if (success) {
      currentRoom.value = roomId;
      statusMessage.value =
          'Sistema listo — reconociendo ${_mlService.currentRoomName}';
    } else {
      statusMessage.value = 'Error al cargar el modelo para $roomId';
    }

    isInitializing.value = false;
  }

  Future<void> switchRoom(String roomId) async {
    if (roomId == currentRoom.value) return;
    await initializeRoom(roomId);
  }

  // ── Procesamiento de imagen ───────────────────────────────────────────────
  /// Llamado desde la UI después de obtener el File de la imagen.
  /// La lógica de conversión ui.Image se mantiene en el widget por ahora
  /// y se pasa el resultado de ML directamente.
  void setRecognitionResult(RecognitionResult? result) {
    recognitionResult.value = result;
    if (result != null) {
      final recognized = result.className != 'Objeto no reconocido';
      statusMessage.value = recognized
          ? 'Selecciona un elemento para más información'
          : 'Elemento no identificado en esta sala';
    }
  }

  void setProcessing(bool value) => isProcessing.value = value;

  void setStatus(String message) => statusMessage.value = message;

  // ── Getters útiles para la UI ─────────────────────────────────────────────
  bool get isReady =>
      !isInitializing.value && !isProcessing.value && currentRoom.value.isNotEmpty;

  MLService get mlService => _mlService;
  String get currentRoomName => _mlService.currentRoomName;
}
