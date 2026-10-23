import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'models/recognition_history.dart';
import 'controllers/auth_controller.dart';
import 'controllers/artwork_controller.dart';
import 'controllers/ai_controller.dart';
import 'controllers/history_controller.dart';
import 'services/local_storage_service.dart';
import 'services/firestore_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'core/middleware/auth_middleware.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ───────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Hive (persistencia local) ──────────────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(RecognitionHistoryAdapter());

  // ── LocalStorageService: abrir box antes de runApp ─────────────────────────
  await Get.putAsync(() => LocalStorageService().init(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Museo y Centro Cultural Rumiñahui',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),

      // ── Inyección de dependencias (GetX) ───────────────────────────────────
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
        Get.put(ArtworkController(), permanent: true);
        Get.put(AiController(), permanent: true);
        Get.put(FirestoreService(), permanent: true);
        Get.put(HistoryController(), permanent: true);
      }),

      // ── Rutas nombradas ────────────────────────────────────────────────────
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const WelcomeScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(
          name: '/home',
          page: () => HomeScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/history',
          page: () => const HistoryScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/ai-chat',
          page: () => const AiChatScreen(),
          middlewares: [AuthMiddleware()],
        ),
      ],
    );
  }
}
