import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controlador de autenticación.
/// Gestiona registro, inicio de sesión y cierre de sesión con Firebase Auth.
/// El estado del usuario es reactivo con GetX; nunca se usa setState.
class AuthController extends GetxController {
  // ── Estado reactivo ──────────────────────────────────────────────────────
  final Rxn<User> user = Rxn<User>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  bool get isLoggedIn => user.value != null;
  String get currentUserId => user.value?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    // Escucha cambios de sesión de Firebase Auth en tiempo real.
    // Cuando el usuario inicia o cierra sesión, [user] se actualiza
    // automáticamente y los Obx que dependen de [isLoggedIn] se reconstruyen.
    user.bindStream(FirebaseAuth.instance.authStateChanges());
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    if (!_validateInputs(email, password)) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Get.offAllNamed('/home');
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
    } catch (e) {
      errorMessage.value = 'Error inesperado. Intenta de nuevo.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Registro ─────────────────────────────────────────────────────────────
  Future<void> register(String email, String password) async {
    if (!_validateInputs(email, password)) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Get.offAllNamed('/home');
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
    } catch (e) {
      errorMessage.value = 'Error inesperado. Intenta de nuevo.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      errorMessage.value = 'Error al cerrar sesión';
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool _validateInputs(String email, String password) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      errorMessage.value = 'Completa todos los campos';
      return false;
    }
    if (!GetUtils.isEmail(email)) {
      errorMessage.value = 'Ingresa un correo válido';
      return false;
    }
    if (password.length < 6) {
      errorMessage.value = 'La contraseña debe tener al menos 6 caracteres';
      return false;
    }
    return true;
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'email-already-in-use':
        return 'El correo ya está registrado';
      case 'invalid-email':
        return 'Correo inválido';
      case 'network-request-failed':
        return 'Sin conexión. Verifica tu internet';
      default:
        return 'Error de autenticación ($code)';
    }
  }
}
