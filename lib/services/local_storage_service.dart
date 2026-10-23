import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import '../models/recognition_history.dart';
import '../core/constants/app_constants.dart';

/// Servicio singleton para persistencia local con Hive.
/// Guarda el historial de reconocimientos de manera offline-first.
class LocalStorageService extends GetxService {
  static LocalStorageService get to => Get.find();

  /// Inicializa el box de Hive. Llamar en main.dart antes de runApp.
  Future<LocalStorageService> init() async {
    await Hive.openBox<RecognitionHistory>(AppConstants.historyBox);
    return this;
  }

  Box<RecognitionHistory> get _box =>
      Hive.box<RecognitionHistory>(AppConstants.historyBox);

  /// Guarda un nuevo reconocimiento. Si supera el límite, elimina el más antiguo.
  Future<void> saveRecognition(RecognitionHistory entry) async {
    await _box.add(entry);
    if (_box.length > AppConstants.maxHistoryEntries) {
      await _box.deleteAt(0);
    }
  }

  /// Retorna el historial completo, del más reciente al más antiguo.
  List<RecognitionHistory> getHistory() =>
      _box.values.toList().reversed.toList();

  /// Retorna solo los elementos marcados como favoritos.
  List<RecognitionHistory> getFavorites() =>
      _box.values.where((e) => e.isFavorite).toList().reversed.toList();

  /// Alterna el estado de favorito de un elemento.
  Future<void> toggleFavorite(RecognitionHistory item) async {
    item.isFavorite = !item.isFavorite;
    await item.save();
  }

  /// Elimina un elemento del historial.
  Future<void> deleteEntry(RecognitionHistory item) async {
    await item.delete();
  }

  /// Borra todo el historial local.
  Future<void> clearHistory() async {
    await _box.clear();
  }

  /// Cantidad total de entradas en el historial.
  int get historyCount => _box.length;
}
