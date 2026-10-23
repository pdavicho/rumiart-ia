import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

/// Middleware que protege rutas que requieren autenticación.
///
/// Uso en GetPage:
/// ```dart
/// GetPage(
///   name: '/home',
///   page: () => HomeScreen(),
///   middlewares: [AuthMiddleware()],
/// )
/// ```
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    // Si no hay sesión activa, redirige al login
    if (!auth.isLoggedIn) {
      return const RouteSettings(name: '/login');
    }
    return null; // continúa normalmente
  }
}
