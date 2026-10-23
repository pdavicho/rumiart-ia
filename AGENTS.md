# AGENTS.md — RumiArt IA

Este archivo describe el proyecto para agentes de código (Copilot, Cursor, Antigravity, etc.).

## Descripción del proyecto

**RumiArt IA** es una app Flutter de reconocimiento de obras de arte para el **Museo y Centro Cultural Rumiñahui** (Sangolquí, Ecuador). Usa TFLite para reconocimiento visual, Firebase para auth y persistencia remota, Hive para persistencia local, y un backend FastAPI+Gemini en Render para el asistente IA.

## Stack tecnológico

- **Flutter** 3.24+ con GetX (state management, routing, DI)
- **Firebase Auth** — autenticación Email/Password
- **Cloud Firestore** — obras de arte + logs de reconocimiento colaborativos
- **Hive** — historial local offline-first
- **TFLite** — modelos de clasificación de imágenes por sala
- **FastAPI + Gemini 1.5 Flash** — backend IA en Render
- **GitHub Actions** — CI (analyze+test) y CD (APK release)

## Convenciones del proyecto

- **Nombres en español** para variables de dominio (sala, obra, artista, etc.)
- **GetX** para todo el estado: nunca `setState` en pantallas principales
- **Constantes** en `lib/core/constants/app_constants.dart`
- **API keys** NUNCA en código Dart — van en el backend o en `--dart-define`
- Los **TODOs** comentados en el código indican pasos pendientes por fase

## Estructura de capas

```
Screens → Controllers → Services → Firebase/Hive/HTTP
                     → Models
```

## Archivos críticos

| Archivo | Propósito |
|---|---|
| `lib/main.dart` | Entry point, inicialización Firebase+Hive, rutas GetX |
| `lib/firebase_options.dart` | Config Firebase (generado por flutterfire_cli) |
| `lib/core/constants/app_constants.dart` | URLs, colecciones, thresholds |
| `lib/controllers/auth_controller.dart` | Login/register/logout con Firebase |
| `lib/controllers/artwork_controller.dart` | Carga obras desde Firestore + fallback local |
| `lib/controllers/ai_controller.dart` | Chat con backend IA |
| `lib/controllers/history_controller.dart` | Historial local (Hive) |
| `lib/services/local_storage_service.dart` | CRUD Hive |
| `lib/services/firestore_service.dart` | CRUD recognition_logs en Firestore |
| `lib/services/ml_service.dart` | Inferencia TFLite |
| `scripts/seed_firestore.dart` | Sube las 19 obras (ejecutar UNA sola vez) |
| `backend/main.py` | Backend FastAPI+Gemini |
| `firestore.rules` | Reglas de seguridad Firestore |

## Colecciones Firestore

| Colección | Descripción |
|---|---|
| `artworks` | 19 obras de arte (seed desde script) |
| `recognition_logs` | Logs de reconocimientos de todos los usuarios |

## Variables de entorno / Secrets

- `GEMINI_API_KEY` → en Render, para el backend Python
- `GOOGLE_SERVICES_JSON` → en GitHub Secrets (base64 del archivo JSON)
- `AI_BACKEND_URL` → en GitHub Secrets, inyectado con `--dart-define`

## Comandos frecuentes

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run scripts/seed_firestore.dart
flutter run --dart-define=AI_BACKEND_URL=https://rumiart-ia-backend.onrender.com
flutter build apk --release --dart-define=AI_BACKEND_URL=...
git tag v1.0.0 && git push origin v1.0.0
```
