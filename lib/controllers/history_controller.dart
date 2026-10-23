import 'package:get/get.dart';
import '../services/local_storage_service.dart';
import '../models/recognition_history.dart';

/// Controlador GetX para el historial local de reconocimientos.
class HistoryController extends GetxController {
  final history = <RecognitionHistory>[].obs;
  final favorites = <RecognitionHistory>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  void _loadHistory() {
    history.assignAll(LocalStorageService.to.getHistory());
    favorites.assignAll(LocalStorageService.to.getFavorites());
  }

  Future<void> toggleFavorite(RecognitionHistory item) async {
    await LocalStorageService.to.toggleFavorite(item);
    _loadHistory();
  }

  Future<void> deleteEntry(RecognitionHistory item) async {
    await LocalStorageService.to.deleteEntry(item);
    _loadHistory();
  }

  Future<void> clearAll() async {
    await LocalStorageService.to.clearHistory();
    _loadHistory();
  }

  /// Recarga el historial (útil tras un nuevo reconocimiento).
  @override
  void refresh() => _loadHistory();
}
