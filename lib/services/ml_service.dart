import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class RecognitionResult {
  final String className;
  final double confidence;
  final String objectInfo;

  RecognitionResult({
    required this.className,
    required this.confidence,
    required this.objectInfo,
  });
}

class RoomModel {
  final String modelPath;
  final String labelsPath;
  final String roomName;
  final Map<String, Map<String, String>> artworkDatabase;

  RoomModel({
    required this.modelPath,
    required this.labelsPath,
    required this.roomName,
    required this.artworkDatabase,
  });
}

class MLService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  String _currentRoom = '';
  
  // ConfiguraciÃ³n de las salas
  static final Map<String, RoomModel> _roomConfigs = {
    'sala1': RoomModel(
      modelPath: 'assets/models/sala1_model.tflite',
      labelsPath: 'assets/models/sala1_labels.txt',
      roomName: 'Sala 1 - Primeros Pobladores',
      artworkDatabase: {
        '0': {
          'nombre': 'Olla Globular',
          'artista': 'Cultura Cosanga',
          'descripcion': 'Olla de barro precolombina de procedencia Cosanga, caracterizada por un cuerpo globular y un cuello corto. Presenta la forma tÃ­pica de las piezas utilitarias de la regiÃ³n.',
        },
        '1': {
          'nombre': 'Plato PentÃ¡podo',
          'artista': 'Cultura Jama Coaque',
          'descripcion': 'Recipiente ceremonial de cinco patas y con decoraciones particulares, utilizado para ofrendas y rituales.',
        },
        '2': {
          'nombre': 'Plato TrÃ­pode',
          'artista': 'Cultura Precolombina',
          'descripcion': 'Recipiente ceremonial de tres patas, utilizado para ofrendas y rituales.',
        },
        '3': {
          'nombre': 'Plato TrÃ­pode',
          'artista': 'Cultura Precolombina',
          'descripcion': 'Segunda variante de vasija trÃ­pode con decoraciones particulares.',
        },
      },
    ),
    'sala4': RoomModel(
      modelPath: 'assets/models/sala4_model.tflite',
      labelsPath: 'assets/models/sala4_labels.txt',
      roomName: 'Sala 4 - El MaÃ­z',
      artworkDatabase: {
        '0': {
          'nombre': 'Planos del MaÃ­z',
          'artista': 'Gonzalo Endara Crow',
          'descripcion': 'Planos arquitÃ©ctonicos originales del monumento de "El Choclo", construido en 1989 realizada con hierro y hormigÃ³n.',
        },
        '1': {
          'nombre': 'No Existe',
          'artista': 'Elemento de Control',
          'descripcion': 'Elemento de control para el sistema de reconocimiento, utilizado para pruebas tÃ©cnicas.',
        },
      },
    ),
    'sala6': RoomModel(
      modelPath: 'assets/models/sala6_model.tflite',
      labelsPath: 'assets/models/sala6_labels.txt',
      roomName: 'Sala 6 - La CantonizaciÃ³n',
      artworkDatabase: {
        '0': {
          'nombre': 'Chagra',
          'artista': 'Arte Tradicional',
          'descripcion': 'Figura tradicional del campesino andino, sÃ­mbolo del trabajo agrÃ­cola y de las actividades ganaderas. Representa la identidad cultural y la tradiciÃ³n popular del cantÃ³n RumiÃ±ahui.',
        },
        '1': {
          'nombre': 'Pingullero',
          'artista': 'MÃºsica Tradicional',
          'descripcion': 'MÃºsico tradicional que entonan el pingÃ¼llo y el tambor mama, convocan a la gente a importante celebraciones como el Inti Raymi, Corpus Christi, entre otros.',
        },
        '2': {
          'nombre': 'Ruco',
          'artista': 'SabidurÃ­a Ancestral',
          'descripcion': 'Considerados hijos de la tierra, son sÃ­mbolos de longevidad, sabidurÃ­a y tradiciÃ³n. Portadores de conocimientos y prÃ¡cticas ancestrales, representan a los danzantes tradicionales de la regiÃ³n andina del Ecuador.',
        },
      },
    ),
    'sala5': RoomModel(
      modelPath: 'assets/models/sala5_model.tflite',
      labelsPath: 'assets/models/sala5_labels.txt',
      roomName: 'Sala 5 - PlÃ¡stica Ecuatoriana',
      artworkDatabase: {
        '0': {
          'nombre': 'El caballo azul - RÃ©plica',
          'artista': 'Gonzalo Endara Crow',
          'descripcion': 'Nombre asignado por la comunidad, ya que Gonzalo Endara Crow no solÃ­a poner tÃ­tulos a sus pinturas. La obra original se encuentra en Guayaquil y constituye un claro ejemplo de realismo mÃ¡gico dentro de su producciÃ³n pictÃ³rica.',
        },
        '1': {
          'nombre': 'Retrato de Juan de Salinas',
          'artista': 'Retrato HistÃ³rico',
          'descripcion': 'RepresentaciÃ³n de Juan Salinas, prÃ³cer de la Independencia ecuatoriana. ParticipÃ³ de la gesta del Primer Grito de Independencia en Quito el 10 de agosto de 1809.',
        },
        '2': {
          'nombre': 'La rendiciÃ³n',
          'artista': 'Eduardo Kingman Riofrio',
          'descripcion': 'Obra representativa en la que las manos simbolizan fuerza, lucha, trabajo, sacrificio y amor. Es atribuida al pintor ecuatoriano Eduardo Kingman, aunque no consta en la base de datos oficial de la familia Kingman.',
        },
        '3': {
          'nombre': 'Retrato de SimÃ³n BolÃ­var',
          'artista': 'Oswaldo GuayasamÃ­n',
          'descripcion': 'RepresentaciÃ³n del Libertador SimÃ³n BolÃ­var, figura principal de la emancipaciÃ³n hispanoamericana del Imperio EspaÃ±ol y fundador de las repÃºplicas de la Gran Colombia y Bolivia.',
        },
      },
    ),
    'sala2': RoomModel(
      modelPath: 'assets/models/sala2_model.tflite',
      labelsPath: 'assets/models/sala2_labels.txt',
      roomName: 'Sala 2 - La Colonia',
      artworkDatabase: {
        '0': {
          'nombre': 'Crucifijo',
          'artista': 'NA',
          'descripcion': 'Cruz cristiana tallada en madera, utilizada como sÃ­mbolo central del cristianismo y empleada en ceremonias religiosas para la evangelizaciÃ³n y enseÃ±anza de los pueblos indÃ­genas de la Ã©poca.',
        },
        '1': {
          'nombre': 'Hacienda Chillo CompaÃ±ia',
          'artista': 'NA',
          'descripcion': 'En el siglo XVII, las haciendas jesuitas del Valle de los Chillos se destacaron como las mÃ¡s productivas de la regiÃ³n. Desde sus inicios tuvieron gran importancia, pues albergaron y hospedaron a diversos cientÃ­ficos europeos que visitaron la zona.',
        },
        '2': {
          'nombre': 'Cacique Juan ZangolquÃ­',
          'artista': 'NA',
          'descripcion': 'El Cacique de Urin Chillo, vivÃ­a en la cabecera del pueblo donde tenia 1135 personas sujetas a Ã©l. Casado con MarÃ­a Xumasa, tuvo 15 hijos.',
        },
        '3': {
          'nombre': 'VolcÃ¡n Cotopaxi',
          'artista': 'NA',
          'descripcion': 'RepresentaciÃ³n artÃ­stica del volcÃ¡n Cotopaxi, el segundo volcÃ¡n mÃ¡s alto de Ecuador con una altitud de 5897 metros sobre el nÃ­vel del mar, que se caracteriza por su cono simÃ©trico cubierto de nieve y glaciares.',
        },
      },
    ),
    'sala3': RoomModel(
      modelPath: 'assets/models/sala3_model.tflite',
      labelsPath: 'assets/models/sala3_labels.txt',
      roomName: 'Sala 3 - La Independencia',
      artworkDatabase: {
        '0': {
          'nombre': 'Juan de Salinas',
          'artista': 'PrÃ³cer Libertario SangolquileÃ±o',
          'descripcion': 'Militar e ilustrado criollo, considerado el primer comandante del ejÃ©rcito ecuatoriano. LiderÃ³ las milicias patriÃ³ticas y es reconocido como prÃ³cer de la Independencia. NaciÃ³ en Conocoto y fue inscrito en SangolquÃ­.',
        },
        '1': {
          'nombre': 'Juan PÃ­o MontÃºfar',
          'artista': 'MarquÃ©s de Selva Alegre',
          'descripcion': 'IntegrÃ³ la Ã©lite ilustrada de Quito y fue un importante promotor de la cultura, las ciencias y las ideas liberales. Tras el Primer Grito de Independencia asumiÃ³ el cargo de regente, desempeÃ±Ã¡ndose como director.',
        },
        '2': {
          'nombre': 'Rosa MontÃºfar',
          'artista': 'PrÃ³cer SangolquileÃ±a',
          'descripcion': 'SÃ­mbolo femenino de la Independencia ecuatoriana, representa la valentÃ­a y participaciÃ³n de las mujeres en un proceso histÃ³rico tradicionalmente dominado por figuras masculinas. PrÃ³cer sangolquileÃ±a profundamente comprometida con la causa libertaria, estuvo casada con Vicente Aguirre y colaborÃ³ con las milicias patriotas proveyÃ©ndolas de armamento, incluidos fusiles nuevos. Lamentablemente, falleciÃ³ en la pobreza.',
        },
        '3': {
          'nombre': 'Lucas TipÃ¡n',
          'artista': 'El Chasqui Libertador',
          'descripcion': 'ParticipÃ³ como guÃ­a, mensajero y espÃ­a al servicio del ejÃ©rcito libertador durante la campaÃ±a de liberaciÃ³n de la Real Audiencia de Quito.',
        },
      },
    ),
  };

  // Getter para obtener las salas disponibles
  static List<String> get availableRooms => _roomConfigs.keys.toList();
  
  // Getter para obtener informaciÃ³n de la sala actual
  String get currentRoom => _currentRoom;
  String get currentRoomName => _roomConfigs[_currentRoom]?.roomName ?? '';
  
  bool get isInitialized => _isInitialized;

  /// Inicializar modelo para una sala especÃ­fica
  Future<bool> initializeForRoom(String roomId) async {
    try {
      print('ðŸ”„ Inicializando TensorFlow Lite para $roomId...');
      
      if (!_roomConfigs.containsKey(roomId)) {
        print('âŒ Sala $roomId no encontrada');
        return false;
      }

      final roomConfig = _roomConfigs[roomId]!;

      // Limpiar modelo anterior si existe
      if (_interpreter != null) {
        _interpreter!.close();
        _interpreter = null;
      }

      // Configurar opciones del intÃ©rprete
      final options = InterpreterOptions();
      
      // Activar GPU Delegate en Android
      if (Platform.isAndroid) {
        try {
          options.addDelegate(GpuDelegate());
          print('âœ… GPU Delegate activado');
        } catch (e) {
          print('âš ï¸ GPU no disponible, usando CPU');
        }
      }

      // Cargar modelo
      _interpreter = await Interpreter.fromAsset(
        roomConfig.modelPath,
        options: options,
      );

      // Cargar labels
      final labelsData = await rootBundle.loadString(roomConfig.labelsPath);
      _labels = labelsData.trim().split('\n');

      _currentRoom = roomId;
      _isInitialized = true;

      print('âœ… Modelo TensorFlow Lite cargado exitosamente para ${roomConfig.roomName}');
      print('ðŸ“Š Labels encontradas: ${_labels.length}');
      
      for (int i = 0; i < _labels.length; i++) {
        print('ðŸ·ï¸ Clase $i: ${_labels[i]}');
      }

      // Obtener informaciÃ³n del modelo
      final inputTensor = _interpreter!.getInputTensors().first;
      final outputTensor = _interpreter!.getOutputTensors().first;
      
      print('ðŸ“ Input shape: ${inputTensor.shape}');
      print('ðŸ“ Output shape: ${outputTensor.shape}');
      print('ðŸ”¢ Input type: ${inputTensor.type}');
      print('ðŸ”¢ Output type: ${outputTensor.type}');

      return true;
    } catch (e) {
      print('âŒ Error al inicializar modelo para $roomId: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Procesar imagen para reconocimiento
  Future<RecognitionResult?> processImage(ui.Image image) async {
    if (!_isInitialized || _interpreter == null) {
      print('âŒ Servicio ML no inicializado');
      return null;
    }

    try {
      print('ðŸ–¼ï¸ Procesando imagen con TensorFlow Lite...');
      print('ðŸ“ Imagen original: ${image.width}x${image.height}');

      // Convertir ui.Image a bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      // Decodificar con image package
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        print('âŒ Error al decodificar imagen');
        return null;
      }

      // Redimensionar imagen a tamaÃ±o del modelo
      final resized = img.copyResize(decodedImage, width: 224, height: 224);

      // Convertir a uint8 (CRÃTICO - no normalizar)
      final inputData = Uint8List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          inputData[pixelIndex++] = pixel.r.toInt(); // 0-255 directamente
          inputData[pixelIndex++] = pixel.g.toInt();
          inputData[pixelIndex++] = pixel.b.toInt();
        }
      }

      // Preparar input tensor - formato simple
      // ignore: unused_local_variable
      final inputTensor = inputData.buffer.asByteData();
      final inputList = List<List<List<List<int>>>>.generate(1, (b) =>
          List<List<List<int>>>.generate(224, (h) =>
              List<List<int>>.generate(224, (w) {
                final pixelStart = (h * 224 + w) * 3;
                return [
                  inputData[pixelStart],     // R
                  inputData[pixelStart + 1], // G
                  inputData[pixelStart + 2], // B
                ];
              })
          )
      );

      // Preparar output tensor
      final outputTensor = List.generate(1, (_) => List.filled(_labels.length, 0));

      print('ðŸ§  Ejecutando inferencia TensorFlow Lite...');
      
      // Medir tiempo de inferencia
      final stopwatch = Stopwatch()..start();
      _interpreter!.run(inputList, outputTensor);
      stopwatch.stop();
      
      print('âš¡ Tiempo de inferencia: ${stopwatch.elapsedMilliseconds}ms');

      // Procesar resultados
      final predictions = outputTensor[0];
      print('ðŸ“Š Scores de confianza (uint8):');
      
      int maxIndex = 0;
      int maxScore = predictions[0];
      
      for (int i = 0; i < predictions.length && i < _labels.length; i++) {
        final percentage = (predictions[i] / 255.0 * 100);
        print('${_labels[i]}: ${predictions[i]}/255 (${percentage.toStringAsFixed(1)}%)');
        
        if (predictions[i] > maxScore) {
          maxScore = predictions[i];
          maxIndex = i;
        }
      }

      print('ðŸŽ¯ Mejor predicciÃ³n: Clase $maxIndex con $maxScore/255 (${(maxScore / 255.0 * 100).toStringAsFixed(1)}%)');

      // Verificar umbral de confianza
      if (maxScore < 128) { // 50% threshold
        print('âš ï¸ Confianza muy baja...');
        return null;
      }

      // Obtener informaciÃ³n del objeto
      final roomConfig = _roomConfigs[_currentRoom]!;
      final objectInfo = roomConfig.artworkDatabase[maxIndex.toString()];
      
      if (objectInfo != null) {
        final result = RecognitionResult(
          className: _labels[maxIndex],
          confidence: maxScore / 255.0,
          objectInfo: '${objectInfo['nombre']}\n'
                     'Artista: ${objectInfo['artista']}\n'
                     'DescripciÃ³n: ${objectInfo['descripcion']}',
        );

        print('âœ… Objeto reconocido: ${result.className} (${roomConfig.roomName})');
        return result;
      } else {
        print('âš ï¸ InformaciÃ³n del objeto no encontrada para clase $maxIndex');
        return null;
      }

    } catch (e) {
      print('âŒ Error durante procesamiento: $e');
      return null;
    }
  }

  /// Cambiar sala activa
  Future<bool> switchToRoom(String roomId) async {
    if (_currentRoom == roomId && _isInitialized) {
      return true; // Ya estamos en esa sala
    }
    
    return await initializeForRoom(roomId);
  }

  /// Obtener lista de objetos de la sala actual
  Map<String, Map<String, String>>? getCurrentRoomArtworks() {
    if (!_isInitialized || _currentRoom.isEmpty) return null;
    return _roomConfigs[_currentRoom]?.artworkDatabase;
  }

  /// Obtener nombres de objetos de la sala actual
  // ignore: unused_element
  List<String> _getObjectNames() {
    if (!_isInitialized || _currentRoom.isEmpty) return [];
    final artworks = _roomConfigs[_currentRoom]?.artworkDatabase;
    if (artworks == null) return [];
    
    return artworks.values.map((artwork) => artwork['nombre'] ?? '').toList();
  }

  /// Limpiar recursos
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _currentRoom = '';
    print('ðŸ§¹ MLService recursos liberados');
  }
}

