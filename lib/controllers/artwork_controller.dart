import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artwork_info.dart';
import '../core/constants/app_constants.dart';

/// Controlador GetX para la carga de obras de arte desde Firestore.
/// Gestiona los estados de carga, vacío y error requeridos por la rúbrica.
class ArtworkController extends GetxController {
  // ── Estado reactivo ──────────────────────────────────────────────────────
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final artworks = <ArtworkInfo>[].obs;

  String _currentSalaId = '';

  // ── Carga desde Firestore ────────────────────────────────────────────────
  Future<void> loadArtworksForRoom(String salaId) async {
    if (_currentSalaId == salaId && artworks.isNotEmpty) return;

    _currentSalaId = salaId;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    artworks.clear();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.artworksCollection)
          .where('salaId', isEqualTo: salaId)
          .orderBy('classIndex')
          .get();

      artworks.assignAll(
        snapshot.docs
            .map((d) => ArtworkInfo.fromFirestore(d.id, d.data()))
            .toList(),
      );

      // Fallback: si Firestore no devuelve nada, usar datos locales
      if (artworks.isEmpty) {
        artworks.assignAll(_localArtworks(salaId));
      }
    } catch (e) {
      // Si hay error de red, cargar desde datos locales
      artworks.assignAll(_localArtworks(salaId));
      if (artworks.isEmpty) {
        hasError.value = true;
        errorMessage.value = _mapError(e);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => loadArtworksForRoom(_currentSalaId);

  /// Busca un artwork por su classIndex dentro de la sala activa.
  ArtworkInfo? findByClassIndex(int classIndex) {
    try {
      return artworks.firstWhere((a) => a.classIndex == classIndex);
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _mapError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    if (msg.contains('permission')) {
      return 'Sin permisos para leer las obras. Inicia sesión de nuevo.';
    }
    return 'Error al cargar las obras. Intenta de nuevo.';
  }

  // ── Datos locales de respaldo (offline fallback) ──────────────────────────
  List<ArtworkInfo> _localArtworks(String salaId) {
    final db = _artworkDb[salaId] ?? {};
    return db.entries.map((e) {
      final idx = int.parse(e.key);
      return ArtworkInfo(
        id: '${salaId}_$idx',
        salaId: salaId,
        classIndex: idx,
        nombre: e.value['nombre']!,
        artista: e.value['artista']!,
        descripcion: e.value['descripcion']!,
        roomName: _roomNames[salaId] ?? salaId,
      );
    }).toList();
  }

  // Datos locales de respaldo (se usan si Firestore no responde)
  static const _roomNames = {
    'sala1': 'Sala 1 - Primeros Pobladores',
    'sala2': 'Sala 2 - La Colonia',
    'sala3': 'Sala 3 - La Independencia',
    'sala4': 'Sala 4 - El Maíz',
    'sala5': 'Sala 5 - Plástica Ecuatoriana',
    'sala6': 'Sala 6 - La Cantonización',
  };

  static const _artworkDb = {
    'sala1': {
      '0': {'nombre': 'Olla Globular', 'artista': 'Cultura Cosanga', 'descripcion': 'Olla de barro precolombina de procedencia Cosanga, caracterizada por un cuerpo globular y un cuello corto.'},
      '1': {'nombre': 'Plato Pentápodo', 'artista': 'Cultura Jama Coaque', 'descripcion': 'Recipiente ceremonial de cinco patas, utilizado para ofrendas y rituales.'},
      '2': {'nombre': 'Plato Trípode', 'artista': 'Cultura Precolombina', 'descripcion': 'Recipiente ceremonial de tres patas, utilizado para ofrendas y rituales.'},
      '3': {'nombre': 'Plato Trípode II', 'artista': 'Cultura Precolombina', 'descripcion': 'Segunda variante de vasija trípode con decoraciones particulares.'},
    },
    'sala2': {
      '0': {'nombre': 'Crucifijo', 'artista': 'NA', 'descripcion': 'Cruz cristiana tallada en madera, empleada en ceremonias religiosas coloniales.'},
      '1': {'nombre': 'Hacienda Chillo Compañía', 'artista': 'NA', 'descripcion': 'Las haciendas jesuitas del Valle de los Chillos fueron las más productivas del siglo XVII.'},
      '2': {'nombre': 'Cacique Juan Zangolquí', 'artista': 'NA', 'descripcion': 'Cacique de Urin Chillo, con 1135 personas sujetas a él.'},
      '3': {'nombre': 'Volcán Cotopaxi', 'artista': 'NA', 'descripcion': 'El segundo volcán más alto de Ecuador con 5897 m.s.n.m.'},
    },
    'sala3': {
      '0': {'nombre': 'Juan de Salinas', 'artista': 'Prócer Libertario Sangolquileño', 'descripcion': 'Primer comandante del ejército ecuatoriano. Prócer de la Independencia.'},
      '1': {'nombre': 'Juan Pío Montúfar', 'artista': 'Marqués de Selva Alegre', 'descripcion': 'Promotor de la cultura y las ideas liberales tras el Primer Grito de Independencia.'},
      '2': {'nombre': 'Rosa Montúfar', 'artista': 'Prócer Sangolquileña', 'descripcion': 'Símbolo femenino de la Independencia ecuatoriana. Proveyó armamento a las milicias.'},
      '3': {'nombre': 'Lucas Tipán', 'artista': 'El Chasqui Libertador', 'descripcion': 'Guía, mensajero y espía al servicio del ejército libertador.'},
    },
    'sala4': {
      '0': {'nombre': 'Planos del Maíz', 'artista': 'Gonzalo Endara Crow', 'descripcion': 'Planos originales del monumento "El Choclo", construido en 1989.'},
      '1': {'nombre': 'Elemento de Control', 'artista': 'Control', 'descripcion': 'Elemento de control para el sistema de reconocimiento.'},
    },
    'sala5': {
      '0': {'nombre': 'El caballo azul - Réplica', 'artista': 'Gonzalo Endara Crow', 'descripcion': 'Ejemplo de realismo mágico. La obra original se encuentra en Guayaquil.'},
      '1': {'nombre': 'Retrato de Juan de Salinas', 'artista': 'Retrato Histórico', 'descripcion': 'Representación de Juan Salinas, prócer del Primer Grito de Independencia.'},
      '2': {'nombre': 'La rendición', 'artista': 'Eduardo Kingman Riofrio', 'descripcion': 'Las manos simbolizan fuerza, lucha, trabajo y amor.'},
      '3': {'nombre': 'Retrato de Simón Bolívar', 'artista': 'Oswaldo Guayasamín', 'descripcion': 'Representación del Libertador, fundador de la Gran Colombia y Bolivia.'},
    },
    'sala6': {
      '0': {'nombre': 'Chagra', 'artista': 'Arte Tradicional', 'descripcion': 'Figura del campesino andino, símbolo del trabajo agrícola del cantón Rumiñahui.'},
      '1': {'nombre': 'Pingullero', 'artista': 'Música Tradicional', 'descripcion': 'Músico que convoca a celebraciones como el Inti Raymi y el Corpus Christi.'},
      '2': {'nombre': 'Ruco', 'artista': 'Sabiduría Ancestral', 'descripcion': 'Símbolo de longevidad y sabiduría. Danzante tradicional de la región andina.'},
    },
  };
}
