import 'package:hive/hive.dart';

part 'recognition_history.g.dart';

/// Registro de un reconocimiento visual guardado localmente con Hive.
/// Persiste entre reinicios de la app.
@HiveType(typeId: 0)
class RecognitionHistory extends HiveObject {
  @HiveField(0)
  late String artworkId;

  @HiveField(1)
  late String artworkName;

  @HiveField(2)
  late String artista;

  @HiveField(3)
  late String sala;

  @HiveField(4)
  late String salaId;

  @HiveField(5)
  late DateTime timestamp;

  @HiveField(6)
  late double confidence;

  @HiveField(7)
  late bool isFavorite;

  RecognitionHistory({
    required this.artworkId,
    required this.artworkName,
    required this.artista,
    required this.sala,
    required this.salaId,
    required this.timestamp,
    required this.confidence,
    this.isFavorite = false,
  });

  @override
  String toString() =>
      'RecognitionHistory{artworkName: $artworkName, sala: $sala, '
      'timestamp: $timestamp, isFavorite: $isFavorite}';
}
