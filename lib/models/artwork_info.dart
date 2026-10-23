/// Información de una obra de arte tal como viene de Firestore.
/// Reemplaza los datos hardcodeados que estaban en MLService.
class ArtworkInfo {
  final String id;
  final String salaId;
  final int classIndex;
  final String nombre;
  final String artista;
  final String descripcion;
  final String roomName;

  const ArtworkInfo({
    required this.id,
    required this.salaId,
    required this.classIndex,
    required this.nombre,
    required this.artista,
    required this.descripcion,
    required this.roomName,
  });

  /// Construye una [ArtworkInfo] desde un documento de Firestore.
  factory ArtworkInfo.fromFirestore(String docId, Map<String, dynamic> data) {
    return ArtworkInfo(
      id: docId,
      salaId: data['salaId'] as String,
      classIndex: data['classIndex'] as int,
      nombre: data['nombre'] as String,
      artista: data['artista'] as String,
      descripcion: data['descripcion'] as String,
      roomName: data['roomName'] as String,
    );
  }

  /// Convierte a Map para guardar en Firestore.
  Map<String, dynamic> toFirestore() => {
        'salaId': salaId,
        'classIndex': classIndex,
        'nombre': nombre,
        'artista': artista,
        'descripcion': descripcion,
        'roomName': roomName,
      };

  /// Texto listo para narrar con TTS o mostrar en el modal.
  String get fullDescription =>
      '$nombre\nArtista: $artista\nDescripción: $descripcion';

  @override
  String toString() => 'ArtworkInfo{nombre: $nombre, sala: $salaId}';
}