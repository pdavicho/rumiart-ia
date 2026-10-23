# 📋 Bitácora de Desarrollo — RumiArt IA
## Proyecto Final · Curso Flutter e IA · Entrega: 26 oct 8:00 a.m.

---

## 🗓️ Sesión 3 — 23 de octubre 2026

### ✅ Todo lo que se completó hoy

| Archivo/Tarea | Estado |
|---|---|
| `scripts/seed_firestore.py` | ✅ 21 obras subidas a Firestore |
| `lib/models/recognition_history.g.dart` | ✅ Generado con build_runner |
| `lib/services/local_storage_service.dart` | ✅ CRUD Hive completo |
| `lib/services/firestore_service.dart` | ✅ CRUD recognition_logs + stream |
| `lib/controllers/history_controller.dart` | ✅ GetX reactive |
| `lib/controllers/ai_controller.dart` | ✅ HTTP + Gemini backend activado |
| `lib/screens/history_screen.dart` | ✅ 2 tabs: historial local + comunidad |
| `lib/screens/ai_chat_screen.dart` | ✅ Chat completo con animación |
| `lib/main.dart` | ✅ Todos los servicios registrados + rutas /history y /ai-chat |
| `backend/main.py` | ✅ FastAPI + Gemini 1.5 Flash |
| `backend/requirements.txt` | ✅ |
| `render.yaml` | ✅ Config deploy Render |
| `.github/workflows/ci.yml` | ✅ CI: analyze + test en cada push |
| `.github/workflows/release.yml` | ✅ CD: APK en cada tag v* |
| `README.md` | ✅ Completo con arquitectura |
| `AGENTS.md` | ✅ Actualizado |
| `flutter analyze` | ✅ Sin warnings (solo info en archivos viejos) |

---

## 🔜 Pendiente CRÍTICO para la entrega

### 1. Integrar reconocimiento → guardar en Hive + Firestore (30 min)
En `home_screen.dart`, dentro de `_processImage()`, después de obtener el resultado:
```dart
// AGREGAR tras obtener `result`:
final artwork = /* buscar en ArtworkController por classIndex */;
if (artwork != null && result.className != 'Objeto no reconocido') {
  final entry = RecognitionHistory(
    artworkId: artwork.id,
    artworkName: artwork.nombre,
    artista: artwork.artista,
    sala: artwork.roomName,
    salaId: _currentRoom,
    timestamp: DateTime.now(),
    confidence: result.confidence / 255.0,
  );
  await LocalStorageService.to.saveRecognition(entry);
  await FirestoreService.to.saveRecognitionLog(...);
  AiController ai = Get.find(); ai.setArtworkContext(...);
}
```

### 2. Agregar botones de navegación en HomeScreen (15 min)
Agregar en el AppBar o como botones flotantes:
- Botón → `/history`
- Botón → `/ai-chat`

### 3. Deploy backend en Render (20 min)
1. Push del código a GitHub
2. Conectar repo en render.com
3. Configurar variable `GEMINI_API_KEY`
4. Copiar la URL del servicio

### 4. Configurar GitHub Secrets (10 min)
- `GOOGLE_SERVICES_JSON` (base64 del json)
- `AI_BACKEND_URL` (URL de Render)

### 5. Tag v1.0.0 y verificar CI (10 min)
```bash
git add .
git commit -m "feat: app completa RumiArt IA v1.0.0"
git tag v1.0.0
git push origin main --tags
```

---

## 📊 Estado rúbrica actualizado

| Criterio | Peso | Estado |
|----------|------|--------|
| Persistencia remota/colaborativa | 20% | ✅ Firestore CRUD + stream comunidad |
| Autenticación | 15% | ✅ Firebase Auth completo |
| Datos reales (≥15 registros) | 15% | ✅ 21 obras en Firestore |
| Persistencia local | 10% | ✅ Hive completo con favoritos |
| Estado con GetX | 10% | 🔄 Falta integrar save en home_screen |
| IA sin secretos | 10% | ✅ Backend en Render (falta deploy) |
| Manejo de errores | 10% | ✅ Widgets + mapeo de errores |
| Arquitectura en capas | 5% | ✅ Screens→Controllers→Services→Models |
| Documentación + CI/CD | 5% | ✅ README + GitHub Actions |

---

## 🛠️ Próximos comandos

```bash
# 1. Correr la app para probar
flutter run --dart-define=AI_BACKEND_URL=https://rumiart-ia-backend.onrender.com

# 2. Cuando el backend esté en Render, hacer el release
git tag v1.0.0 && git push origin v1.0.0
```
