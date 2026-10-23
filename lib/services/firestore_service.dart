import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/constants/app_constants.dart';

/// Servicio para CRUD de recognition_logs en Firestore.
/// Cada reconocimiento exitoso se guarda aquí para la vista colaborativa.
class FirestoreService extends GetxService {
  static FirestoreService get to => Get.find();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  String? get _userEmail => FirebaseAuth.instance.currentUser?.email;

  /// Guarda un log de reconocimiento en Firestore.
  /// No hace nada si el usuario no está autenticado.
  Future<void> saveRecognitionLog({
    required String artworkId,
    required String artworkName,
    required String artista,
    required String salaId,
    required String sala,
    required double confidence,
  }) async {
    if (_userId == null) return;

    try {
      await _db.collection(AppConstants.recognitionLogsCollection).add({
        'userId': _userId,
        'userEmail': _userEmail ?? 'Anónimo',
        'artworkId': artworkId,
        'artworkName': artworkName,
        'artista': artista,
        'salaId': salaId,
        'sala': sala,
        'confidence': confidence,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService.saveRecognitionLog error: $e');
    }
  }

  /// Stream en tiempo real de los últimos [limit] reconocimientos de todos los usuarios.
  Stream<QuerySnapshot> streamRecentLogs({int limit = 50}) {
    if (_userId == null) return const Stream.empty();
    return _db
        .collection(AppConstants.recognitionLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Cantidad de reconocimientos del usuario actual.
  Future<int> getMyLogCount() async {
    if (_userId == null) return 0;
    try {
      final snap = await _db
          .collection(AppConstants.recognitionLogsCollection)
          .where('userId', isEqualTo: _userId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('FirestoreService.getMyLogCount error: $e');
      return 0;
    }
  }
}
