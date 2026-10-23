import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/ml_service.dart';
import '../services/tts_service.dart';

final TTSService _ttsService = TTSService();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MLService _mlService = MLService();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  
  bool _isInitializing = false;
  bool _isProcessing = false;
  String _status = 'Selecciona una sala para comenzar';
  RecognitionResult? _recognitionResult;
  String _currentRoom = '';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Inicializar con Sala 1 por defecto
    _initializeRoom('sala1');
  }

  Future<void> _initializeRoom(String roomId) async {
    setState(() {
      _isInitializing = true;
      _status = 'Inicializando modelo para $roomId...';
      _recognitionResult = null;
    });

    _animationController.forward();
    
    final success = await _mlService.initializeForRoom(roomId);
    
    setState(() {
      _isInitializing = false;
      _currentRoom = roomId;
      if (success) {
        _status = 'Sistema Listo, reconociendo elementos de ${_mlService.currentRoomName}';
      } else {
        _status = 'Error al cargar modelo para $roomId';
      }
    });
    
    _animationController.reverse();
  }

  Future<void> _switchRoom(String roomId) async {
    if (roomId == _currentRoom) return;
    await _initializeRoom(roomId);
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        await _processImage(File(photo.path));
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      setState(() {
        _status = 'Error al acceder a la cÃ¡mara';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      setState(() {
        _status = 'Error al acceder a la galerÃ­a';
      });
    }
  }

  // Actualizar _processImage para pasar la imagen al modal
  Future<void> _processImage(File imageFile) async {
    if (!_mlService.isInitialized) {
      setState(() {
        _status = 'Modelo no inicializado';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Analizando imagen...';
    });

    try {
      // Leer imagen
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      
      if (decodedImage == null) {
        setState(() {
          _status = 'Error al decodificar imagen';
          _isProcessing = false;
        });
        return;
      }

      // Convertir a ui.Image
      final ui.Image uiImage = await _convertToUiImage(decodedImage);
      
      // Procesar con ML
      final result = await _mlService.processImage(uiImage);
      
      setState(() {
        _isProcessing = false;
        if (result != null) {
          final bool isRecognized = result.className != 'Objeto no reconocido';
          _status = isRecognized 
              //? 'Objeto reconocido con ${(result.confidence * 100).toStringAsFixed(1)}% de confianza'
              ? 'Selecciona un elemento para mÃ¡s informaciÃ³n'
              : 'Elemento no identificado en esta sala';
          
          // ðŸŽ‰ PASAR LA IMAGEN AL MODAL
          // ── Guardar reconocimiento exitoso en Hive + Firestore ───────────
          if (isRecognized) {
            final salaName = _mlService.currentRoomName;
            final confidence = result.confidence / 255.0;
            final artworkId = '_';

            // Guardar localmente (Hive)
            final histEntry = RecognitionHistory(
              artworkId: artworkId,
              artworkName: result.className,
              artista: result.objectInfo.contains('|') ? result.objectInfo.split('|')[0].trim() : '',
              sala: salaName,
              salaId: _currentRoom,
              timestamp: DateTime.now(),
              confidence: confidence,
            );
            LocalStorageService.to.saveRecognition(histEntry).then((_) {
              if (Get.isRegistered<HistoryController>()) {
                Get.find<HistoryController>().refresh();
              }
            });

            // Guardar en Firestore (colaborativo)
            FirestoreService.to.saveRecognitionLog(
              artworkId: artworkId,
              artworkName: result.className,
              artista: '',
              salaId: _currentRoom,
              sala: salaName,
              confidence: confidence,
            );

            // Configurar contexto del asistente IA
            if (Get.isRegistered<AiController>()) {
              Get.find<AiController>().setArtworkContext(
                artworkName: result.className,
                artista: '',
                sala: salaName,
                descripcion: result.objectInfo,
              );
            }
          }
          // ─────────────────────────────────────────────────────────────────
          _showRecognitionModal(result, imageFile);
        } else {
          _status = 'No se pudo procesar la imagen';
        }
      });

    } catch (e) {
      print('Error al procesar imagen: $e');
      setState(() {
        _isProcessing = false;
        _status = 'Error al procesar imagen';
      });
    }
  }

  Future<ui.Image> _convertToUiImage(img.Image image) async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      img.encodePng(image),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final logoSize = isSmallScreen ? 48.0 : 64.0;
    final titleSize = isSmallScreen ? 18.0 : 22.0;
    final subtitleSize = isSmallScreen ? 13.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B0E3F), // Morado muy oscuro del welcome
            Color(0xFF4A148C), // Morado profundo
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6A1B9A).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/RU-blanco.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: isSmallScreen ? 32 : 40,
                      );
                    },
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Departamento de InvestigaciÃ³n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RumiArt IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Botones de navegación ──────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white70),
                  tooltip: 'Historial',
                  onPressed: () => Get.toNamed('/history'),
                ),
                IconButton(
                  icon: const Icon(Icons.smart_toy, color: Color(0xFF00E5FF)),
                  tooltip: 'Asistente IA',
                  onPressed: () => Get.toNamed('/ai-chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final margin = isSmallScreen ? 10.0 : 16.0;
    final spacing = isSmallScreen ? 6.0 : 12.0;

    return Container(
      margin: EdgeInsets.all(margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF00E5FF), size: isSmallScreen ? 16 : 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Selecciona la Sala',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: margin),

          // Primera fila: Salas 1, 2, 3
          Row(
            children: [
              Expanded(child: _buildRoomCard('sala1', 'Sala 1', 'Primeros Pobladores', Icons.groups)),
              SizedBox(width: spacing),
              Expanded(child: _buildRoomCard('sala2', 'Sala 2', 'La Colonia', Icons.castle)),
              SizedBox(width: spacing),
              Expanded(child: _buildRoomCard('sala3', 'Sala 3', 'La Independencia', Icons.flag)),
            ],
          ),
          SizedBox(height: spacing),

          // Segunda fila: Salas 4, 5, 6
          Row(
            children: [
              Expanded(child: _buildRoomCard('sala4', 'Sala 4', 'El MaÃ­z', Icons.eco)),
              SizedBox(width: spacing),
              Expanded(child: _buildRoomCard('sala5', 'Sala 5', 'PlÃ¡stica Ecuatoriana', Icons.brush)),
              SizedBox(width: spacing),
              Expanded(child: _buildRoomCard('sala6', 'Sala 6', 'La CantonizaciÃ³n', Icons.celebration)),
            ],
          ),

          if (_currentRoom.isNotEmpty) ...[
            SizedBox(height: margin),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomCard(String roomId, String title, String subtitle, IconData icon) {
    final bool isActive = _currentRoom == roomId;
    final bool isLoading = _isInitializing && _currentRoom == roomId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final cardPadding = isSmallScreen ? 8.0 : 12.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;
    final titleSize = isSmallScreen ? 10.0 : 12.0;
    final subtitleSize = isSmallScreen ? 8.0 : 10.0;

    return GestureDetector(
      onTap: (_isInitializing || _isProcessing) ? null : () => _switchRoom(roomId),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                )
              : null,
          color: isActive ? null : Color(0xFF6A1B9A).withOpacity(0.2),
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
          border: Border.all(
            color: isActive ? Color(0xFFFF9800) : Color(0xFF6A1B9A).withOpacity(0.6),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive) BoxShadow(
              color: Color(0xFFFF9800).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isActive ? Colors.white : Colors.white70,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: iconSize,
                color: isActive ? Colors.white : Colors.white70,
              ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.white,
                ),
              ),
            ),
            SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: isActive ? Colors.white70 : Colors.white60,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool buttonsEnabled = !_isInitializing && !_isProcessing && _currentRoom.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;
    final fontSize = isSmallScreen ? 13.0 : 14.0;
    final iconSize = isSmallScreen ? 18.0 : 24.0;

    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 10 : 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: buttonsEnabled ? _pickImageFromCamera : null,
                  icon: _isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B0E3F))),
                        )
                      : Icon(Icons.camera_alt, size: iconSize),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Tomar Foto', style: TextStyle(fontSize: fontSize)),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 8),
                    backgroundColor: Color(0xFFFF9800),
                    foregroundColor: Color(0xFF1B0E3F),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12)),
                    elevation: 3,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: buttonsEnabled ? _pickImageFromGallery : null,
                  icon: Icon(Icons.photo_library, size: iconSize),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('GalerÃ­a', style: TextStyle(fontSize: fontSize)),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 8),
                    backgroundColor: Color(0xFF00E5FF),
                    foregroundColor: Color(0xFF1B0E3F),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    Color statusColor;
    IconData statusIcon;

    if (_isInitializing || _isProcessing) {
      statusColor = Color(0xFFFF9800);
      statusIcon = Icons.hourglass_empty;
    } else if (_mlService.isInitialized) {
      statusColor = Color(0xFF00E5FF);
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Color(0xFFE91E63);
      statusIcon = Icons.error;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 16, vertical: 8),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF6A1B9A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(color: Color(0xFF6A1B9A).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          if (_isInitializing || _isProcessing)
            SizedBox(
              width: isSmallScreen ? 16 : 20,
              height: isSmallScreen ? 16 : 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Icon(statusIcon, color: statusColor, size: isSmallScreen ? 16 : 20),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 13 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRecognitionResult() {
    if (_recognitionResult == null) return SizedBox.shrink();

    final bool isNotRecognized = _recognitionResult!.className == 'Objeto no reconocido';
    final Color primaryColor = isNotRecognized ? Color(0xFFFF9800) : Color(0xFF00E5FF);
    final Color backgroundColor = isNotRecognized 
        ? Color(0xFF6A1B9A).withOpacity(0.1) 
        : Color(0xFF4A148C).withOpacity(0.1);
    final Color borderColor = isNotRecognized 
        ? Color(0xFF6A1B9A).withOpacity(0.5) 
        : Color(0xFF4A148C).withOpacity(0.5);
    final IconData icon = isNotRecognized ? Icons.help_outline : Icons.verified;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  isNotRecognized ? 'Elemento no identificado' : 'Objeto Reconocido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (!isNotRecognized) ...[
            _buildDetailRow('Objeto', _recognitionResult!.className, Icons.art_track),
            //_buildDetailRow('Confianza', '${(_recognitionResult!.confidence * 100).toStringAsFixed(1)}%', Icons.analytics),
            _buildDetailRow('Sala', _mlService.currentRoomName, Icons.room),
            _buildDetailRow(' ', _mlService.currentRoomName, Icons.room),
            SizedBox(height: 16),
          ],
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF6A1B9A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isNotRecognized ? Icons.lightbulb_outline : Icons.info_outline,
                      color: primaryColor,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isNotRecognized ? 'Sugerencias:' : 'InformaciÃ³n:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _recognitionResult!.objectInfo,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          if (isNotRecognized) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pickImageFromCamera(),
                icon: Icon(Icons.camera_alt, size: 18),
                label: Text('Intentar de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white60),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Reemplazar la funciÃ³n _showRecognitionModal con esta versiÃ³n responsive

void _showRecognitionModal(RecognitionResult result, File imageFile) {
  final bool isNotRecognized = result.className == 'Objeto no reconocido';

  // Limpiar el nombre de la clase
  String cleanClassName = result.className;
  if (!isNotRecognized) {
    cleanClassName = cleanClassName.replaceFirst(RegExp(r'^\d+\s*'), '');
    cleanClassName = cleanClassName.replaceAll('_', ' ');
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.8),
    builder: (BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final isSmallScreen = screenWidth < 360;
      final isShortScreen = screenHeight < 600;

      // TamaÃ±os adaptativos
      final modalPadding = isSmallScreen ? 12.0 : 16.0;
      final contentPadding = isSmallScreen ? 14.0 : 20.0;
      final imageSize = isSmallScreen ? 50.0 : 60.0;
      final titleSize = isSmallScreen ? 14.0 : 16.0;
      final bodySize = isSmallScreen ? 12.0 : 13.0;
      final labelSize = isSmallScreen ? 13.0 : 14.0;
      final buttonPadding = isSmallScreen ? 10.0 : 12.0;
      final iconSize = isSmallScreen ? 16.0 : 18.0;
      final spacing = isSmallScreen ? 10.0 : 12.0;

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(modalPadding),
            child: Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * (isShortScreen ? 0.9 : 0.8),
              ),
              child: Stack(
                children: [
                  // Contenido principal del modal
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(contentPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1B0E3F),
                          Color(0xFF4A148C),
                          Color(0xFF6A1B9A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                      border: Border.all(
                        color: isNotRecognized ? Color(0xFFFF9800) : Color(0xFF00E5FF),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isNotRecognized ? Color(0xFFFF9800) : Color(0xFF00E5FF)).withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header con imagen y tÃ­tulo
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imagen del objeto
                              Container(
                                width: imageSize,
                                height: imageSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                  border: Border.all(
                                    color: isNotRecognized ? Color(0xFFFF9800) : Color(0xFF00E5FF),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isNotRecognized ? Color(0xFFFF9800) : Color(0xFF00E5FF)).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 10),
                                  child: Image.file(
                                    imageFile,
                                    width: imageSize,
                                    height: imageSize,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isNotRecognized ? Color(0xFFFF9800) : Color(0xFF00E5FF),
                                          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 10),
                                        ),
                                        child: Icon(
                                          isNotRecognized ? Icons.help_outline : Icons.verified,
                                          color: Color(0xFF1B0E3F),
                                          size: isSmallScreen ? 22 : 28,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isNotRecognized ? 'Elemento no identificado' : 'RumiArt IA ha reconocido',
                                      style: TextStyle(
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isSmallScreen ? 14 : 20),

                          if (!isNotRecognized) ...[
                            // InformaciÃ³n del objeto
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Color(0xFF6A1B9A).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                border: Border.all(
                                  color: Color(0xFF6A1B9A).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre del objeto con botÃ³n de audio
                                  Row(
                                    children: [
                                      Icon(Icons.art_track, color: Color(0xFF00E5FF), size: iconSize),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cleanClassName,
                                          style: TextStyle(
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      // BOTÃ“N DE AUDIO
                                      GestureDetector(
                                        onTap: () async {
                                          await _ttsService.speak(result.objectInfo);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                          decoration: BoxDecoration(
                                            color: _ttsService.isSpeaking
                                                ? Color(0xFFFF9800)
                                                : Color(0xFF00E5FF),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (_ttsService.isSpeaking
                                                    ? Color(0xFFFF9800)
                                                    : Color(0xFF00E5FF)).withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _ttsService.isSpeaking ? Icons.volume_up : Icons.play_arrow,
                                            color: Color(0xFF1B0E3F),
                                            size: iconSize,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: spacing),

                                  // Sala actual
                                  Row(
                                    children: [
                                      Icon(Icons.room, color: Color(0xFFFF9800), size: iconSize - 2),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_mlService.currentRoomName}',
                                          style: TextStyle(
                                            fontSize: labelSize,
                                            color: Colors.white70,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: spacing),

                                  // LÃ­nea divisoria
                                  Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.2),
                                  ),

                                  SizedBox(height: spacing),

                                  // InformaciÃ³n detallada
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: iconSize - 2),
                                      SizedBox(width: 8),
                                      Text(
                                        'InformaciÃ³n:',
                                        style: TextStyle(
                                          fontSize: labelSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 8),

                                  Text(
                                    result.objectInfo,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.4,
                                      fontSize: bodySize,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 14 : 20),

                            // Botones de acciÃ³n
                            if (_ttsService.isSpeaking) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _ttsService.stop();
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.stop, size: iconSize),
                                  label: FittedBox(child: Text('Detener Audio')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFF9800),
                                    foregroundColor: Color(0xFF1B0E3F),
                                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing),
                            ],

                            // Botones principales
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _ttsService.stop();
                                      Navigator.of(context).pop();
                                      _pickImageFromCamera();
                                    },
                                    icon: Icon(Icons.camera_alt, size: iconSize),
                                    label: FittedBox(child: Text('Nueva Foto')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF6A1B9A),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                      ),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _ttsService.stop();
                                      Navigator.of(context).pop();
                                    },
                                    icon: Icon(Icons.check, size: iconSize),
                                    label: FittedBox(child: Text('Entendido')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF00E5FF),
                                      foregroundColor: Color(0xFF1B0E3F),
                                      padding: EdgeInsets.symmetric(vertical: buttonPadding, horizontal: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                      ),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Contenido para objeto no reconocido
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Color(0xFF6A1B9A).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                border: Border.all(
                                  color: Color(0xFFFF9800).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Color(0xFFFF9800),
                                    size: isSmallScreen ? 32 : 40,
                                  ),

                                  SizedBox(height: spacing),

                                  Text(
                                    'Sugerencias:',
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  Text(
                                    result.objectInfo,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.4,
                                      fontSize: bodySize,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 14 : 20),

                            // BotÃ³n para intentar de nuevo
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _ttsService.stop();
                                  Navigator.of(context).pop();
                                  _pickImageFromCamera();
                                },
                                icon: Icon(Icons.refresh, size: iconSize),
                                label: Text('Intentar de nuevo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF9800),
                                  foregroundColor: Color(0xFF1B0E3F),
                                  padding: EdgeInsets.symmetric(vertical: buttonPadding + 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // BotÃ³n de cerrar
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        _ttsService.stop();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildFooter() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 16, horizontal: isSmallScreen ? 12 : 20),
      child: Text(
        'PDMN - CJLG | v.1.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTestTTSButton() {
  return Container(
    margin: EdgeInsets.all(16),
    child: ElevatedButton.icon(
      onPressed: () async {
        await _ttsService.speak("Hola, esto es una prueba de audio para el sistema de reconocimiento de objetos del museo");
      },
      icon: Icon(Icons.volume_up),
      label: Text('Probar Audio'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}


// build()
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B0E3F),
            Color(0xFF4A148C),
            Color(0xFF6A1B9A),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRoomSelector(),
                  _buildStatusIndicator(),
                  _buildActionButtons(),
                  
                  if (_status.contains('reconocido') || _status.contains('identificado'))
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF6A1B9A).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF00E5FF).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.museum_rounded,
                            color: Color(0xFF00E5FF),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Arte con IA',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          _buildFooter(),
        ],
      ),
    ),
  );
}


  @override
  void dispose() {
    _animationController.dispose();
    _mlService.dispose();
    super.dispose();
  }
}