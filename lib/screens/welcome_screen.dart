import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Iniciar animaciÃ³n
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _navigateToHome() {
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn) {
      Get.offAllNamed('/home');
    } else {
      Get.toNamed('/login');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isShortScreen = screenHeight < 600;

    // TamaÃ±os adaptativos
    final logoSize = isSmallScreen ? 120.0 : (isShortScreen ? 130.0 : 173.0);
    final titleWelcome = isSmallScreen ? 18.0 : 24.0;
    final titleMain = isSmallScreen ? 20.0 : (isShortScreen ? 24.0 : 28.0);
    final subtitleSize = isSmallScreen ? 13.0 : 16.0;
    final infoSize = isSmallScreen ? 14.0 : 18.0;
    final buttonFontSize = isSmallScreen ? 14.0 : 18.0;
    final horizontalPadding = isSmallScreen ? 16.0 : 32.0;
    final verticalSpacing = isShortScreen ? 16.0 : 32.0;
    final infoBoxPadding = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B0E3F), // Morado muy oscuro
              Color(0xFF4A148C), // Morado profundo
              Color(0xFF6A1B9A), // Morado medio
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isShortScreen ? 16 : 32),
                        // Logo/TÃ­tulo animado
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: AnimatedBuilder(
                                animation: _fadeInAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeInAnimation.value,
                                    child: Column(
                                      children: [
                                        // Logo personalizado
                                        ClipOval(
                                          child: Image.asset(
                                            'assets/images/logoRumiArtIA.png',
                                            width: logoSize,
                                            height: logoSize,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.account_balance,
                                                size: logoSize * 0.5,
                                                color: Color(0xFF1565C0),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(height: verticalSpacing),

                                        // TÃ­tulo principal
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Bienvenidos al',
                                            style: TextStyle(
                                              fontSize: titleWelcome,
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(height: 8),

                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'MUSEO Y CENTRO\nCULTURAL RUMIÃ‘AHUI',
                                            style: TextStyle(
                                              fontSize: titleMain,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.5,
                                              height: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                        SizedBox(height: isShortScreen ? 16 : 24),

                                        // SubtÃ­tulo
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 12 : 20,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: Colors.white.withOpacity(0.1),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Reconocimiento Inteligente de Obras',
                                              style: TextStyle(
                                                fontSize: subtitleSize,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        SizedBox(height: isShortScreen ? 24 : 48),

                        // InformaciÃ³n de salas
                        AnimatedBuilder(
                          animation: _fadeInAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeInAnimation.value * 0.9,
                              child: Container(
                                padding: EdgeInsets.all(infoBoxPadding),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoRow(Icons.meeting_room, '6 Salas TemÃ¡ticas', infoSize),
                                    SizedBox(height: isSmallScreen ? 8 : 12),
                                    _buildInfoRow(Icons.image_search, '19 Objetos Reconocibles', infoSize),
                                    SizedBox(height: isSmallScreen ? 8 : 12),
                                    _buildInfoRow(Icons.psychology, 'Inteligencia Artificial', infoSize),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: isShortScreen ? 16 : 32),
                      ],
                    ),
                  ),
                ),
              ),

              // BotÃ³n de entrada
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
                child: AnimatedBuilder(
                  animation: _fadeInAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeInAnimation.value,
                      child: Column(
                        children: [
                          // BotÃ³n principal
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 48 : 56,
                            child: ElevatedButton(
                              onPressed: _navigateToHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF9800),
                                foregroundColor: Color(0xFF2D1B69),
                                elevation: 8,
                                shadowColor: Color(0xFFFF9800).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 28),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'COMENZAR RECORRIDO',
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: fontSize + 2),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}